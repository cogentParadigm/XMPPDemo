//
//  AppController.swift
//  XMPPDraft
//
//  Created by Ali Gangji on 4/11/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPFramework
import CDAL

class AppController: NSObject, MessagingDelegate {
    let factories = FactoryFactory(host: "http://localhost")
    
    lazy var ui:UIFactory = {
        return self.factories.ui
    }()
    
    lazy var controllers:ControllerFactory = {
        return self.factories.controllers
    }()
    
    lazy var io:IOFactory = {
        return self.factories.io
    }()
    
    lazy var window:UIWindow = {
        return self.ui.createWindow()
    }()
    
    lazy var navigation:UINavigationController = {
        return self.ui.createNavigation(root: UIViewController())
    }()
    
    lazy var messages:MessagingCoordinator = {
        let messages = self.io.messages
        messages.delegate = self
        return messages
    }()
    
    var hasConnectedMessaging = false
    
    func start() {
        factories.cd.manager.setup() {
            self.messages.connect()
            self.hasConnectedMessaging = true
        }
    }
    
    func connected() {
        DispatchQueue.main.async() {
            let controller = self.controllers.createMessagesController()
            self.open(controller: controller)
        }
    }
    
    func open(controller:UIViewController) {
        navigation.setViewControllers([controller], animated: true)
    }
    
    func openMessageFromUser(user: XMPPUserCoreDataStorageObject) {
        let list = controllers.createMessagesController()
        let message = messages.chatController(recipient: user)
        navigation.setViewControllers([list, message], animated: true)
    }
    
    func save() {
        factories.cd.db.save()
    }
    
    func stop() {
        save()
        messages.disconnect()
    }
    
}
