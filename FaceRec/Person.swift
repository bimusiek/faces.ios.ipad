//
//  Person.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 09/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

class Person {
    var image:UIImage
    var identifier:String
    init(image:UIImage, identifier:String) {
        self.image = image
        self.identifier = identifier
    }
}