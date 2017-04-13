//
//  ControllerFactory.swift
//  XMPPDraft
//
//  Created by Ali Gangji on 4/11/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPFramework

class ControllerFactory: NSObject {
    
    let factories:FactoryFactory
    
    init(factories:FactoryFactory) {
        self.factories = factories
        super.init()
    }
    func createMessagesController() -> MessagesViewController {
        return MessagesViewController(coordinator:factories.io.messages)
    }
    func createContactListController() -> ContactListTableViewController {
        return ContactListTableViewController(coordinator:factories.io.messages)
    }
    func createChatViewController(user:XMPPUserCoreDataStorageObject) -> ChatViewController {
        return factories.io.messages.chatController(recipient: user)
    }
}

extension UIViewController {
    var controllers:ControllerFactory {
        return (UIApplication.shared.delegate as! AppDelegate).app.controllers
    }
}
