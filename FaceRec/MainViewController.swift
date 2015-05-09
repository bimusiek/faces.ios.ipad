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
@objc
class MainViewController:UIViewController, iCarouselDataSource, iCarouselDelegate {
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var faceView: UIImageView!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var advertLabel: UILabel!
    
    @IBOutlet weak var productNameLabel: UILabel!
    
    @IBOutlet weak var productDescriptionLabel: UILabel!
    
    @IBOutlet weak var carousel: iCarousel!
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
        self.carousel.dataSource = self
        self.carousel.delegate = self
        self.carousel.type = .Rotary
        
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
    
    // MARK - iCarousel
    
    func numberOfItemsInCarousel(carousel: iCarousel!) -> Int
    {
        return 3
    }
    
    @objc
    func carousel(carousel: iCarousel!, viewForItemAtIndex index: Int, reusingView viewM: UIView!) -> UIView!
    {
        var label: UILabel! = nil
        var view = viewM
        
        //create new view if no view is available for recycling
        if (view == nil)
        {
            //don't do anything specific to the index within
            //this `if (view == nil) {...}` statement because the view will be
            //recycled and used with other index values later
            let width = self.carousel.bounds.size.width - 150;
            let height = self.carousel.bounds.size.height - 100;
            view = UIImageView(frame:CGRectMake(0, 0, width, height))
            view.contentMode = UIViewContentMode.ScaleAspectFit
            view.clipsToBounds = true;
            (view as! UIImageView!).image = UIImage(named: "page.png")

            label = UILabel(frame:view.bounds)
            label.backgroundColor = UIColor.clearColor()
            label.textAlignment = .Center
            label.font = label.font.fontWithSize(50)
            label.tag = 1
            view.addSubview(label)
        }
        else
        {
            //get a reference to the label in the recycled view
            label = view.viewWithTag(1) as! UILabel!
        }
        
        //set item label
        //remember to always set any properties of your carousel item
        //views outside of the `if (view == nil) {...}` check otherwise
        //you'll get weird issues with carousel item content appearing
        //in the wrong place in the carousel
        label.text = "2"
        
        return view
    }
    
    func carousel(carousel: iCarousel!, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        return value
    }
    
}
