//
//  IOFactory.swift
//  XMPPDraft
//
//  Created by Ali Gangji on 4/11/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPClient

class IOFactory: NSObject {
    
    let factories:FactoryFactory
    
    lazy var xmpp:XMPPDefaultClient = {
        return XMPPDefaultClient()
    }()
    
    lazy var messages:MessagingCoordinator = {
        return MessagingCoordinator(client:self.xmpp, username: "abdul@localhost", password:"test")
    }()
    
    init(factories:FactoryFactory) {
        self.factories = factories
        super.init()
    }
}
