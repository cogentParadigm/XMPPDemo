//
//  CDALDeviceList.swift
//  Pods
//
//  Created by Ali Gangji on 4/13/16.
//
//

class CDALDeviceList: NSObject, NSFilePresenter {
    
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue
    
    public init(url:URL, queue:OperationQueue) {
        presentedItemURL = url
        presentedItemOperationQueue = queue
        super.init()
    }
    
    func presentedItemDidChange() {
        
    }
    
    func accommodatePresentedItemDeletion(completionHandler: @escaping (Error?) -> Void) {
        completionHandler(nil)
    }
    
}
