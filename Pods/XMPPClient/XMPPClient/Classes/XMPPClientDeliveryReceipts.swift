//
//  XMPPClientDeliveryReceipts.swift
//  Pods
//
//  Created by Ali Gangji on 6/19/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientDeliveryReceipts: NSObject {
    open lazy var receipts: XMPPMessageDeliveryReceipts = {
        let receipts = XMPPMessageDeliveryReceipts(dispatchQueue: DispatchQueue.main)!
        receipts.autoSendMessageDeliveryReceipts = true
        receipts.autoSendMessageDeliveryRequests = true
        return receipts
    }()
    
    open func setup(_ connection:XMPPClientConnection) {
        connection.activate(receipts)
    }
    
    open func teardown() {
        receipts.deactivate()
    }
}
