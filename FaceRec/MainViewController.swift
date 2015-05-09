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
    case NotRecognized, GotFace, TooManyFaces;
}

class MainViewController:UIViewController {
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var advertLabel: UILabel!
    
    
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
        }.throttle(1).subscribeNext { (_) -> Void in
            self.state = .NotRecognized
        }
        
        RACObserve(self, "processingNewPerson").subscribeNext { (_) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.stateWasUpdated()
            })
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
                if let grayFace = self.faceDetector.grayFaceWithIndex(0) {
                    faceDetected(face, grayImage: grayFace)
                }
            }
        } else if detectedFaces.count > 1 {
            NSLog("Too many faces! \(detectedFaces.count)", "");
            self.state = .TooManyFaces
        }
    }
    var facesDetected = 0
    func faceDetected(image:UIImage, grayImage:UIImage) {
        self.facesDetected++
        
        if self.state == .GotFace {
            self.checkConfidence(image, grayImage: grayImage)
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
            self.currentPerson = nil
            self.lastPerson = nil
            self.facesDetected = 0
            self.processingLastConfidence = false;
            self.cameraView.hidden = false;
            self.faceView.hidden = true;
            self.confidenceLabel.text = "No one in range"
            self.nameLabel.text = "Hi stranger! Take a look!"
        case .TooManyFaces:
            self.confidenceLabel.text = "Too many faces in front!"
        case .GotFace:
            self.gotFace()
            self.confidenceLabel.text = ""
        default:
            break
        }
        self.faceLoadingIndicator.hidden = !self.processingNewPerson
        if(self.processingNewPerson) {
            self.confidenceLabel.text = "Loading..."
        }
    }
    
    dynamic var processingLastConfidence = false;
    dynamic var processingNewPerson = false;
    func checkConfidence(face:UIImage, grayImage:UIImage) {
        if self.processingLastConfidence {
            return
        }
        
        self.processingLastConfidence = true;
        dispatch_async(dispatch_get_global_queue(0, 0), { [weak self] () -> Void in
            
            var confidence:Double = 0;
            var identifier:String!
            if let weakSelf = self {
                if weakSelf.faceRecognizer.labels().count <= 0 {
                    weakSelf.processingNewPerson = true
                    weakSelf.createPerson(face, grayFace:grayImage, callback: { [weak self] (faceId) -> () in
                        weakSelf.processingNewPerson = false
                        weakSelf.gotFaceModel(faceId)
                        })
                } else {
                    identifier = weakSelf.faceRecognizer.predict(grayImage, confidence: &confidence)
                    weakSelf.confidenceFound(confidence, face: face, grayFace:grayImage, identifier: identifier)
                }
            }
        });
    }
    
    func createPerson(face:UIImage, grayFace:UIImage, callback:(face:FaceModel)->()) {
        var identifier = "\(self.faceRecognizer.labels().count)"
        self.faceRecognizer.updateWithFace(grayFace, name: identifier)
        Faces.getOrCreateByIdentifier(face, identifier: identifier, callback: { [weak self] (face) -> () in
            callback(face: face)
        })
    }
    
    func confidenceFound(confidence:Double, face:UIImage, grayFace:UIImage, var identifier:String) {
        if confidence > 150 {
            self.createPerson(face, grayFace:grayFace, callback:{ [weak self] (face) -> () in
                self?.gotFaceModel(face)
            })
        } else {
            Faces.getOrCreateByIdentifier(face, identifier: identifier, callback: { [weak self] (face) -> () in
                self?.gotFaceModel(face)
            })
        }
    }
    
    func gotFaceModel(face:FaceModel) {
        objc_sync_enter(face)
        self.processingLastConfidence = false;
        objc_sync_exit(face)
        
        self.currentPerson = face
        self.state = .GotFace
    }
    
    func gotFace() {
        self.cameraView.hidden = true;
        self.faceView.hidden = false;
        
        if self.lastPerson?.faceId != self.currentPerson?.faceId {
            self.lastPerson = self.currentPerson
        }
        self.faceView.image = self.currentPerson?.getImage()
        if let currentPerson = self.currentPerson {
            self.nameLabel.text = "Hi \(currentPerson.name)"
        }
        
    }
}
