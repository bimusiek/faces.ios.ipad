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
    var name = ""
    var email = ""
    var avatarUrl = ""
    
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
            "name": "name",
            "email": "email",
            "avatar": "avatarUrl",
            ])
        return mapping
    }
    
    func downloadImage() -> UIImage? {
        if let url = NSURL(string: self.avatarUrl) {
            if let data = NSData(contentsOfURL: url) {
                return UIImage(data: data)
            }
        }
        return nil
    }
}
//{"id":3,"email":"bartosz@hernas.pl","name":"Bartosz Hernas","avatar":"http://faces.hern.as/media/images/1b6853bf-9ae8-4a00-afde-2af11103f830.10202937621320306"}