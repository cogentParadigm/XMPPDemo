//
//  XMPPClientLastActivity.swift
//  Pods
//
//  Created by Ali Gangji on 6/19/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientLastActivity: NSObject {
    
    open lazy var activity: XMPPLastActivity = {
       return XMPPLastActivity()
    }()
    
    open func setup(_ connection:XMPPClientConnection) {
        connection.activate(activity)
    }
    
    open func teardown() {
        activity.deactivate()
    }
}
