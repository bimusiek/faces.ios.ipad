//
//  Faces.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation
import RealmSwift

class Faces {
    class func getOrCreateByIdentifier(image:UIImage, identifier:String, callback:(face:FaceModel)->(), fail:()->()) {
        var firstResult:FaceModel?
        autoreleasepool {
            let identifierResults = Realm().objects(FaceIdentifierModel).filter("identifier = %@", identifier)
            
            if identifierResults.count > 0 {
                let firstIden = identifierResults.first!
                firstResult = firstIden.face
            }
        }
        
        
        if firstResult == nil {
            self.getOrCreateFace(image, identifier:identifier, callback: { (faceId) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if faceId.isEmpty {
                        fail()
                    } else {
                        let face = FaceModel.get(faceId)!
                        callback(face: face)
                    }
                })
            })
        } else {
            let face = firstResult!
            let faceId = face.faceId
            if faceId == FaceModel.UNRECOGNIZED_FACE {
                autoreleasepool {
                    Realm().write {
                        face.imagePath = self.saveImage(image, identifier:identifier)
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let face = FaceModel.get(faceId)!
                callback(face: face)
            })
        }
    }
    
    class func getOrCreateFace(var image:UIImage, identifier:String, callback:(faceId:String)->()) {
        API.sharedInstance.detect(image, success: { (user) -> () in
            dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
                if user.userId == 0 {
                    
                    let face = FaceModel.getNotRecognizedFace(user)
                    let faceIdentifier = FaceIdentifierModel()
                    faceIdentifier.identifier = identifier
                    autoreleasepool {
                        Realm().write {
                            face.imagePath = self.saveImage(image, identifier:identifier)
                            face.identifiers.append(faceIdentifier)
                        }
                    }
                    callback(faceId: face.faceId)

                } else {
                    if let userImage = user.downloadImage() {
                        image = userImage
                    }
                    let faceIdentifier = FaceIdentifierModel()
                    faceIdentifier.identifier = identifier
                    
                    let face = FaceModel.createFromUser(user)
                    face.identifiers.append(faceIdentifier)
                    
                    autoreleasepool {
                        let realm = Realm();
                        realm.write {
                            face.imagePath = self.saveImage(image, identifier:identifier)
                            realm.add(face)
                        }
                    }
                    callback(faceId: face.faceId)
                }
            })

        }) { (error) -> () in
            dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
                callback(faceId: "")
            })
        }
    }
    
    class func saveImage(image:UIImage, identifier:String) -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        var relativePath = "face_\(identifier).png"
        var imagePath = paths.stringByAppendingPathComponent(relativePath)
        var error:NSError?
        if !UIImageJPEGRepresentation(image, 100).writeToFile(imagePath, options: .AtomicWrite, error: &error) {
            NSLog("Failed saving image: \(error?.localizedDescription)");
        }
        return relativePath
    }
}