import Foundation


extension RACStream {
    func mapAs<T,U: AnyObject>(block: (T) -> U) -> Self {
        return map({(value: AnyObject!) in
            if let casted = value as? T {
                return block(casted)
            }
            return nil
        })
    }
    func filterAs<T>(block: (T) -> Bool) -> Self {
        return filter({(value: AnyObject!) in
            if let casted = value as? T {
                return block(casted)
            }
            return false
        })
    }
}

public extension RACSignal {
    
    public func subscribeNextAs<T>(block: (T) -> ()) -> RACDisposable {
        return subscribeNext({(value: AnyObject!) in
            if let casted = value as? T {
                block(casted)
            } else {
                println("Trying to cast to \(T.self) but got \(value)")
            }
        })
    }
    public func subscribeNextAs<T>(block: (T) -> (), error: (NSError!) -> ()) -> RACDisposable {
        return subscribeNext({ (value: AnyObject!) -> Void in
            if let casted = value as? T {
                block(casted)
            }
            }, error: error)
    }
    
}

// a struct that replaces the RAC macro
struct RAC  {
    var target : NSObject!
    var keyPath : String!
    var nilValue : AnyObject!
    
    init(_ target: NSObject!, _ keyPath: String, nilValue: AnyObject? = nil) {
        self.target = target
        self.keyPath = keyPath
        self.nilValue = nilValue
    }
    
    func assignSignal(signal : RACSignal) {
        signal.setKeyPath(self.keyPath, onObject: self.target, nilValue: self.nilValue)
    }
}

infix operator => { associativity left precedence 140 }
func => (signal: RACSignal, rac: RAC) {
    rac.assignSignal(signal)
}
func RACObserve(target: NSObject!, keyPath: String) -> RACSignal  {
    return target.rac_valuesForKeyPath(keyPath, observer: target)
}