//
//  AlertBuilder.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

class AlertBuilder: NSObject {
    
    let controller:UIAlertController
    var completion:(()->Void)?
    
    init(title:String, message:String) {
        controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        super.init()
    }
    
    convenience init(title:String, message:String, handler:(()->Void)?) {
        self.init(title:title, message:message)
        setCompletionHandler(handler)
    }
    
    func setCompletionHandler(_ handler:(()->Void)?) -> AlertBuilder {
        completion = handler
        return self
    }
    
    func addAction(_ title:String, handler:@escaping (UIAlertAction)->Void) -> AlertBuilder {
        let action = UIAlertAction(title: title, style: UIAlertActionStyle.default) { (alert:UIAlertAction!) in
            handler(alert)
            if (self.completion != nil) {
                OperationQueue.main.addOperation {
                    self.completion!()
                }
            }
        }
        controller.addAction(action)
        return self
    }
    
    func show() -> AlertBuilder {
        if let target = UIApplication.shared.keyWindow?.rootViewController {
            
            
            if let view:UIView = UIApplication.shared.keyWindow?.subviews.last {
                
                controller.popoverPresentationController?.sourceView = view
                
                target.present(controller, animated: true, completion: nil)
            }
        }
        return self
    }

}
