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
    class func getOrCreateByIdentifier(image:UIImage, identifier:String, callback:(face:FaceModel)->()) {
        let identifierResults = Realm().objects(FaceIdentifierModel).filter("identifier = %@", identifier)
        
        var firstResult:FaceModel?
        if identifierResults.count > 0 {
            let firstIden = identifierResults.first!
            firstResult = firstIden.face
        }
        
        
        if firstResult == nil {
            
            self.getOrCreateFace(image, identifier:identifier, callback: { (faceId) -> () in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let face = FaceModel.get(faceId)!
                    callback(face: face)
                })
            })
            
        } else {
            let faceId = firstResult!.faceId
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let face = FaceModel.get(faceId)!
                callback(face: face)
            })
        }
    }
    
    class func getOrCreateFace(image:UIImage, identifier:String, callback:(faceId:String)->()) {
        API.sharedInstance.detect(image, success: { (user) -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let realm = Realm();
                realm.write {
                    let faceIdentifier = FaceIdentifierModel()
                    faceIdentifier.identifier = identifier
                    
                    let face = FaceModel()
                    face.faceId = "\(user.userId)"
                    face.identifiers.append(faceIdentifier)
                    
                    realm.add(face)
                    
                    callback(faceId: face.faceId)
                }
            })

        }) { (error) -> () in
            
        }
    }
}