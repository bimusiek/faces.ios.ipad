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
    
    var faceDetector:FJFaceDetector!
    
    var faces = [UIImage]()
    
    var state = FaceDetectionState.NotRecognized {
        didSet {
            self.stateWasUpdated()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.faceDetector = FJFaceDetector(cameraView: self.cameraView, scale: 2.0)
        self.faceDetector.facesDetected.subscribeNext { [weak self] (_) -> Void in
            self?.detectedFacesChanged()
        }
        
        self.faceDetector.facesDetected.filter { (_) -> Bool in
            return self.faceDetector.detectedFaces().count > 0
        }.throttle(0.5).subscribeNext { (_) -> Void in
            self.state = .NotRecognized
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
        NSLog("Detected faces: \(detectedFaces.count)", "");

        if detectedFaces.count == 1 {
            if let face = self.faceDetector.faceWithIndex(0) {
                faceDetected(face)
            }
        } else if detectedFaces.count > 1 {
            NSLog("Too many faces! \(detectedFaces.count)", "");
        }
    }
    func faceDetected(image:UIImage) {
        if count(self.faces) >= 5 {
            self.state = .GotFace
            return;
        }
        self.faces.append(image);

        
    }
    
    func stateWasUpdated() {
        switch(self.state) {
        case .NotRecognized:
            self.faces = []
            self.cameraView.hidden = false;
            self.faceView.hidden = true;
            
        case .GotFace:
            self.faceView.image = self.faces.last;
            self.cameraView.hidden = true;
            self.faceView.hidden = false;
            
        case .DiscoveredOnFacebook:
            self.faceView.image = self.faces.last;
            self.cameraView.hidden = true;
            self.faceView.hidden = false;
        }
    }
}
