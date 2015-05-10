//
//  ProductApiModel.swift
//  iOS-OpenCV-FaceRec
//
//  Created by Michał Hernas on 10/05/15.
//  Copyright (c) 2015 Fifteen Jugglers Software. All rights reserved.
//

import Foundation

class ImageApiModel:NSObject {
    var smallUrl = ""
    var image:UIImage?
    
    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "smallUrl": "smallUrl"
            ])
        return mapping
    }
    
    func downloadImage() {
        if let url = NSURL(string: self.smallUrl) {
            if let data = NSData(contentsOfURL: url) {
                self.image = UIImage(data: data)
            }
        }
    }
}

class ProductApiModel:NSObject {
    var productId = 0
    var name = ""
    var brand = ""
    var price = ""
    var images = [ImageApiModel]()
    
    
    class func map(manager:RKObjectManager) {
        manager.addResponseDescriptor(self.responseDescriptor())
    }
    
    class func responseDescriptor() -> RKResponseDescriptor {
        let responseDescriptor = RKResponseDescriptor(mapping: self.mapping(), method: RKRequestMethod.POST, pathPattern: "products/recommendation/", keyPath: nil, statusCodes: RKStatusCodeIndexSetForClass(RKStatusCodeClass.Successful))
        
        return responseDescriptor
    }
    
    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "productId",
            "name": "name",
            "brand": "brand",
            "price": "price",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "images", toKeyPath: "images", withMapping: ImageApiModel.mapping()))
        return mapping
    }
}
//id: 1
//name: "Base layer - black"
//price: "41.00"
//brand: "Bagheera"
//images: [
//id: 1
//largeUrl: "https://i3.ztat.net/large/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//mediumHdUrl: "https://i3.ztat.net/detail_hd/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//orderNumber: 1
//thumbnailHdUrl: "https://i3.ztat.net/thumb_hd/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//mediumUrl: "https://i3.ztat.net/detail/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//largeHdUrl: "https://i3.ztat.net/large_hd/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//smallUrl: "https://i3.ztat.net/catalog/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//type: "UNSPECIFIED"
//smallHdUrl: "https://i3.ztat.net/catalog_hd/BG/34/2B/00/A8/02/BG342B00A-802@1.1.jpg"
//]