//
//  MessagingCoordinator.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPFramework
import XMPPClient

protocol MessagingDelegate {
    func connected()
    func openMessageFromUser(user:XMPPUserCoreDataStorageObject)
}

class MessagingCoordinator: NSObject {
    
    let client:XMPPDefaultClient
    
    let username:String
    let password:String
    
    var chat:ChatViewController?
    
    var delegate:MessagingDelegate?
    
    init(client:XMPPDefaultClient, username:String, password:String) {
        self.client = client
        self.username = username
        self.password = password
    }
    
    func connect() {
        client.delegate = self
        client.connection.delegate = self
        client.connect(username: username, password: password)
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func chatController(recipient:XMPPUserCoreDataStorageObject) -> ChatViewController {
        if let controller = chat, controller.recipient?.jidStr == recipient.jidStr {
            return controller
        } else {
            let controller = ChatViewController(coordinator:self)
            controller.recipient = recipient
            chat = controller
            return controller
        }
    }
    
    func closeChat() {
        chat = nil
    }
    
}

extension MessagingCoordinator: XMPPClientDelegate {
    func xmppClient(_ sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        if let controller = chat, controller.recipient?.jidStr == user.jidStr {
            //this chat is active, so just display the message
            controller.oneStream(sender: sender, didReceiveMessage: message, from: user)
        }
    }
    func xmppClient(_ sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        if let controller = chat, controller.recipient?.jidStr == user.jidStr {
            controller.oneStream(sender: sender, userIsComposing: user)
        }
    }
}

extension MessagingCoordinator: XMPPClientConnectionDelegate {
    func xmppConnectionDidConnect(_ sender: XMPPStream) {
        delegate?.connected()
    }
}
