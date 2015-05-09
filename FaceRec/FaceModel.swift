//
//  FaceModel.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

@objc(FaceIdentifierModel)
class FaceIdentifierModel:RLMObject {
    var identifier:String = ""
}

@objc(FaceModel)
class FaceModel:RLMObject {
    var identifiers = RLMArray(objectClassName: FaceIdentifierModel.className())
    var id:String = ""
    var facebookImage = ""
}