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
    
}