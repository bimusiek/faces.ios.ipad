//
//  Faces.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

class Faces {
    class func getOrCreateByIdentifier(image:UIImage, identifier:String, callback:(faceId:String)->()) {
        let realm = RLMRealm.defaultRealm()
        
        let results = FaceModel.objectsWhere("ANY identifiers.identifier = %@", identifier)
        var firstResult:FaceModel?
        if results.count > 0 {
            firstResult = results[0] as? FaceModel
        }
        
        if firstResult == nil {
            realm.beginWriteTransaction()
            let faceIdentifier = FaceIdentifierModel()
            faceIdentifier.identifier = identifier
            realm.addObject(faceIdentifier)
            realm.commitWriteTransaction()
            self.getOrCreateFace(image, callback: { (face) -> () in
                let realm = RLMRealm.defaultRealm()
                realm.beginWriteTransaction()
                face.identifiers.addObject(faceIdentifier)
                realm.commitWriteTransaction()
                
                let id = face.faceId
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(faceId: id)
                })
            })
            
        } else {
            let id = firstResult!.faceId
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(faceId: id)
            })
        }
    }
    
    class func getOrCreateFace(image:UIImage, callback:(face:FaceModel)->()) {
        let realm = RLMRealm.defaultRealm();
        let face = FaceModel()
        face.faceId = NSUUID().UUIDString
        
        realm.beginWriteTransaction()
        realm.addObject(face)
        realm.commitWriteTransaction()
        
        callback(face: face)
    }
}