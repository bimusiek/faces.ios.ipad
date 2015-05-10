import Foundation

let API_URL = "http://faces.hern.as/"

class API:NSObject {
    
    override init() {
        super.init()
        RestKitObjC.initLogging()
    }
    
    class func URL(method:String) -> String {
        return "\(method)/"
    }
    
    let manager:RKObjectManager = {
        let manager = RKObjectManager(baseURL: NSURL(string: API_URL))
        manager.requestSerializationMIMEType = RKMIMETypeJSON
        manager.HTTPClient.parameterEncoding = AFJSONParameterEncoding
        RestKitObjC.initLogging()
        
        ProductApiModel.map(manager)
        UserApiModel.map(manager)
        
        return manager
        }()
    
    internal class var sharedInstance : API {
        struct Static {
            static let instance : API = API()
        }
        return Static.instance
    }
    
    func detect(image:UIImage, success:(user:UserApiModel)->(), failure:(error:NSError)->()) {
        let request = self.manager.multipartFormRequestWithObject(self, method: RKRequestMethod.POST, path: "/faces/detect/", parameters: nil) { (formData) -> Void in
            formData.appendPartWithFileData(UIImagePNGRepresentation(image), name: "image", fileName: "image.png", mimeType: "image/png")
        }
        
        let operation = self.manager.objectRequestOperationWithRequest(request, success: { (operation, result) -> Void in
            let object = result.firstObject as! UserApiModel
            success(user: object)
        }) { (operation, error) -> Void in
            NSLog("Got error: \(error.localizedDescription)")
            failure(error: error)
        }
        self.manager.enqueueObjectRequestOperation(operation)
    }
    
    
    func getProduct(userId:Int?, success:(product:ProductApiModel)->(), failure:()->()) {
        self.manager.postObject(nil, path: "products/recommendation/", parameters: [:], success: { (operation, result) -> Void in
            if let product = result.firstObject as? ProductApiModel {
                self.downloadAllImages(product.images, callback: {
                    success(product: product)
                })
            }
            
        }) { (operation, error) -> Void in
            
        }
    }
    
    func downloadAllImages(images:[ImageApiModel], callback:()->()) {
        let group = dispatch_group_create()
        let queue = dispatch_get_global_queue(0,0)
        for image in images {
            dispatch_group_enter(group)
            dispatch_async(queue, { () -> Void in
                image.downloadImage()
                dispatch_group_leave(group)
            })
        }
        dispatch_group_notify(group, queue) { () -> Void in
            callback()
        }
    }
}