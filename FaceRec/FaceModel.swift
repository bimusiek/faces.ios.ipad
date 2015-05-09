//
//  FaceModel.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation
import Realm

class FaceIdentifierModel:RLMObject {
    var identifier:String = ""
    var face:FaceModel? {
        return self.linkingObjectsOfClass(FaceModel.className(), forProperty: "identifiers").last as? FaceModel
    }
}

class FaceModel:RLMObject {
    dynamic var identifiers = RLMArray(objectClassName: FaceIdentifierModel.className())
    dynamic var faceId:String = ""
    dynamic var facebookImage = ""
    
    class func get(identifier:String) -> FaceModel? {
        return FaceModel.objectsWhere("faceId = %@", identifier).lastObject() as? FaceModel
    }
}