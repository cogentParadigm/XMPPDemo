//
//  XMPPClientCapabilities.swift
//  Pods
//
//  Created by Ali Gangji on 6/19/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientCapabilities: NSObject {
    
    open lazy var storage: XMPPCapabilitiesCoreDataStorage = {
        return XMPPCapabilitiesCoreDataStorage.sharedInstance()
    }()
    
    open lazy var capabilities: XMPPCapabilities = {
        let capabilities = XMPPCapabilities(capabilitiesStorage:self.storage)!
        capabilities.autoFetchHashedCapabilities = true;
        capabilities.autoFetchNonHashedCapabilities = false;
        return capabilities
    }()
    
    open func setup(_ connection:XMPPClientConnection) {
        connection.activate(capabilities)
    }
    
    open func teardown() {
        capabilities.deactivate()
    }
}
