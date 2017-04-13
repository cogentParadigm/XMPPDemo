//
//  XMPPClientvCard.swift
//  Pods
//
//  Created by Ali Gangji on 6/23/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientvCard: NSObject {

    open lazy var storage: XMPPvCardCoreDataStorage = {
        return XMPPvCardCoreDataStorage.sharedInstance()
    }()
    
    open lazy var temp: XMPPvCardTempModule = {
        return XMPPvCardTempModule(vCardStorage:self.storage)
    }()

    open lazy var avatar: XMPPvCardAvatarModule = {
        return XMPPvCardAvatarModule(vCardTempModule: self.temp)
    }()
    
    var connection:XMPPClientConnection!
    
    open func setup(_ connection:XMPPClientConnection) {
        self.connection = connection
        connection.activate(temp)
        connection.activate(avatar)
    }
    
    open func teardown() {
        avatar.deactivate()
        temp.deactivate()
    }
    
}
