//
//  MainViewController.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation
import UIKit

enum FaceDetectionState {
    case NotRecognized, GotFace, DiscoveredOnFacebook;
}

class MainViewController:UIViewController {
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var faceLoadingIndicator: UIActivityIndicatorView!
    
    var faceDetector:FJFaceDetector!
    var faceRecognizer:FJFaceRecognizer!

    var lastPerson:FaceModel?
    var currentPerson:FaceModel?
    
    var state = FaceDetectionState.NotRecognized {
        didSet {
            
            self.stateWasUpdated()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.faceRecognizer = FJFaceRecognizer()
        
        self.faceDetector = FJFaceDetector(cameraView: self.cameraView, scale: 2.0)
        self.faceDetector.facesDetected.subscribeNext { [weak self] (_) -> Void in
            self?.detectedFacesChanged()
        }
        
        self.faceDetector.facesDetected.filter { (_) -> Bool in
            return self.faceDetector.detectedFaces().count > 0
        }.throttle(5).subscribeNext { (_) -> Void in
            self.state = .NotRecognized
        }
        
        RACObserve(self, "processingNewPerson").subscribeNext { (_) -> Void in
            self.stateWasUpdated()
        }

    }    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.faceDetector.startCapture()
        
        self.cameraView.hidden = false;
        self.faceView.hidden = true;
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.faceDetector.stopCapture()
        
    }
    
    func detectedFacesChanged() {
        let detectedFaces = self.faceDetector.detectedFaces()
//        NSLog("Detected faces: \(detectedFaces.count)", "");

        if detectedFaces.count == 1 {
            if let face = self.faceDetector.faceWithIndex(0) {
                faceDetected(face)
            }
        } else if detectedFaces.count > 1 {
            NSLog("Too many faces! \(detectedFaces.count)", "");
        }
    }
    var facesDetected = 0
    func faceDetected(image:UIImage) {
        self.facesDetected++
        
        if self.state == .GotFace {
            self.checkConfidence(image)
            return
        }

        if self.facesDetected >= 5 {
            self.state = .GotFace
            return;
        }
        
        
    }
    
    func stateWasUpdated() {
        switch(self.state) {
        case .NotRecognized:
            self.facesDetected = 0
            self.cameraView.hidden = false;
            self.faceView.hidden = true;
            
        case .GotFace:
            self.gotFace()
        case .DiscoveredOnFacebook:
            self.cameraView.hidden = true;
            self.faceView.hidden = false;
        }
        
        self.faceLoadingIndicator.hidden = !self.processingNewPerson
    }
    
    dynamic var processingLastConfidence = false;
    dynamic var processingNewPerson = false;
    func checkConfidence(face:UIImage) {
        if self.processingLastConfidence {
            return
        }
        
        self.processingLastConfidence = true;
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            
            var confidence:Double = 0;
            var identifier:String!
            
            if self.faceRecognizer.labels().count <= 0 {
                self.processingNewPerson = true
                self.createPerson(face, callback: { (faceId) -> () in
                    self.processingNewPerson = false
                    self.gotFaceModel(faceId)
                })
            } else {
                identifier = self.faceRecognizer.predict(face, confidence: &confidence)
                self.confidenceFound(confidence, face: face, identifier: identifier)
            }
        });
    }
    
    func createPerson(face:UIImage, callback:(face:FaceModel)->()) {
        var identifier = self.nameForPerson()
        self.faceRecognizer.updateWithFace(face, name: identifier)
        Faces.getOrCreateByIdentifier(face, identifier: identifier, callback: { (face) -> () in
            callback(face: face)
        })
    }
    
    func confidenceFound(confidence:Double, face:UIImage, var identifier:String) {
        if confidence > 150 {
            self.createPerson(face, callback:{ (face) -> () in
                self.gotFaceModel(face)
            })
        } else {
            Faces.getOrCreateByIdentifier(face, identifier: identifier, callback: { (face) -> () in
                self.gotFaceModel(face)
            })
        }
    }
    
    func gotFaceModel(face:FaceModel) {
        self.currentPerson = face
        self.confidenceLabel.text = "Face: \(face.faceId)"
        self.state = .GotFace
        self.processingLastConfidence = false;
        
    }
    
    func nameForPerson() -> String {
        return "Person \(self.faceRecognizer.labels().count)"
    }
    
    func gotFace() {
        self.cameraView.hidden = true;
        self.faceView.hidden = false;
        
        if self.lastPerson?.faceId != self.currentPerson?.faceId {
            self.lastPerson = self.currentPerson
            
            // Get here
//            self.faceView.image = person.image;
        }
    }
}
