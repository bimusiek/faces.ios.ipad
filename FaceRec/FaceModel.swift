//
//  FaceModel.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation
import RealmSwift

class FaceIdentifierModel:Object {
    var identifier:String = ""
    var face:FaceModel? {
        return self.linkingObjects(FaceModel.self, forProperty: "identifiers").last
    }
}

class FaceModel:Object {
    static let UNRECOGNIZED_FACE = "unrecognized"
    
    dynamic var identifiers = List<FaceIdentifierModel>()
    dynamic var faceId:String = ""
    dynamic var imagePath = ""
    dynamic var name = ""
    dynamic var email = ""
    
    class func get(identifier:String) -> FaceModel? {
        return Realm().objects(FaceModel).filter("faceId = %@", identifier).last
    }
    
    class func getNotRecognizedFace() -> FaceModel {
        if let face = Realm().objects(FaceModel).filter("faceId = %@", self.UNRECOGNIZED_FACE).last {
            return face
        }
        var face:FaceModel = FaceModel()
        face.name = "stranger"
        face.faceId = self.UNRECOGNIZED_FACE
        
        let realm = Realm()
        realm.write { () -> Void in
            realm.add(face)
        }
        return face
    }
    
    func getImage() -> UIImage? {
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        var imagePath = paths.stringByAppendingPathComponent(self.imagePath)
        return UIImage(contentsOfFile: imagePath)
    }
    
    class func createFromUser(user:UserApiModel) -> FaceModel {
        let face = FaceModel()
        face.name = user.name
        face.email = user.email
        face.faceId = "\(user.userId)"
        return face
    }
}