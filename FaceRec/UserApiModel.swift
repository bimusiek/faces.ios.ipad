//
//  UserApiModel.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

@objc(UserApiModel)
class UserApiModel:NSObject {
    var userId:Int = 0
    var confidence:Int = 0
    
    class func map(manager:RKObjectManager) {
        manager.addResponseDescriptor(self.responseDescriptor())
    }
    
    class func responseDescriptor() -> RKResponseDescriptor {
        let responseDescriptor = RKResponseDescriptor(mapping: self.mapping(), method: RKRequestMethod.POST, pathPattern: "faces/detect/", keyPath: nil, statusCodes: RKStatusCodeIndexSetForClass(RKStatusCodeClass.Successful))
        
        return responseDescriptor
    }
    
    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "userId",
            "confidence": "confidence",
            ])
        return mapping
    }
}