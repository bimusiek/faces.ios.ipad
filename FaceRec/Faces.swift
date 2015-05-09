//
//  Faces.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

class Faces {
    class func getOrCreateByIdentifier(image:UIImage, identifier:String, callback:(face:FaceModel)->()) {
        let real = RLMRealm.defaultRealm()
        
        real.beginWriteTransaction()
        
        real.commitWriteTransaction()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            
        })
    }
}