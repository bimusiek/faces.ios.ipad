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
    dynamic var identifiers = List<FaceIdentifierModel>()
    dynamic var faceId:String = ""
    dynamic var facebookImage = ""
    
    class func get(identifier:String) -> FaceModel? {
        return Realm().objects(FaceModel).filter("faceId = %@", identifier).last
    }
}