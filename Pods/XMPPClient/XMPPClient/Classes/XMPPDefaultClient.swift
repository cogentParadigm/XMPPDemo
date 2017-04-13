//
//  XMPPClient.swift
//  Pods
//
//  Created by Ali Gangji on 6/18/16.
//
//  a default XMPP Client with access to capabilities, roster, archiving, delivery receipts, and last activity

import Foundation
import XMPPFramework

public typealias XMPPMessageCompletionHandler = (_ stream: XMPPStream, _ message: XMPPMessage) -> Void

public protocol XMPPClientDelegate : NSObjectProtocol {
    func xmppClient(_ sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject)
    func xmppClient(_ sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject)
}

open class XMPPDefaultClient: NSObject {

    open lazy var connection: XMPPClientConnection = {
        let connection = XMPPClientConnection()
        connection.delegate = self
        return connection
    }()
    
    open lazy var archive: XMPPClientArchive = {
        return XMPPClientArchive()
    }()
    
    open lazy var capabilities: XMPPClientCapabilities = {
        return XMPPClientCapabilities()
    }()
    
    open lazy var roster:XMPPClientRoster = {
        return XMPPClientRoster()
    }()
    
    open lazy var vcard:XMPPClientvCard = {
        return XMPPClientvCard()
    }()
    
    open lazy var receipts:XMPPClientDeliveryReceipts = {
        return XMPPClientDeliveryReceipts()
    }()
    
    open var enableArchiving = true
    open var delegate:XMPPClientDelegate?
    
    var messageCompletionHandler:XMPPMessageCompletionHandler?
    var isSetup = false
    
    open func setup() {
        roster.setup(connection)
        vcard.setup(connection)
        capabilities.setup(connection)
        receipts.setup(connection)
        if enableArchiving {
            archive.setup(connection)
        }
        
        connection.getStream().addDelegate(self, delegateQueue: DispatchQueue.main)
        isSetup = true
    }
    
    open func teardown() {
        connection.getStream().removeDelegate(self)
        if enableArchiving {
            archive.teardown()
        }
        receipts.teardown()
        capabilities.teardown()
        vcard.teardown()
        roster.teardown()
        isSetup = false
    }
    
    open func connect(username:String, password:String) {
        if !isSetup {
            setup()
        }
        connection.connect(username: username, password: password)
    }
    
    open func disconnect() {
        connection.disconnect()
        if isSetup {
            teardown()
        }
    }
    
    open func sendMessage(_ message: String, thread:String, to receiver: String, completionHandler completion:@escaping XMPPMessageCompletionHandler) {
        let body = DDXMLElement.element(withName: "body") as! DDXMLElement
        let messageID = connection.getStream().generateUUID()!
        
        body.stringValue = message
        
        let threadElement = DDXMLElement.element(withName: "thread") as! DDXMLElement
        threadElement.stringValue = thread
        
        let completeMessage = DDXMLElement.element(withName: "message") as! DDXMLElement
        
        completeMessage.addAttribute(withName: "id", stringValue: messageID)
        completeMessage.addAttribute(withName: "type", stringValue: "chat")
        completeMessage.addAttribute(withName: "to", stringValue: receiver)
        completeMessage.addChild(body)
        completeMessage.addChild(threadElement)
        
        messageCompletionHandler = completion
        connection.getStream().send(completeMessage)
    }
    
}

extension XMPPDefaultClient: XMPPStreamDelegate {
    
    public func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        if let completion = messageCompletionHandler {
            completion(sender, message)
        }
    }
    
    public func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        let user = roster.storage.user(for: message.from(), xmppStream: connection.getStream(), managedObjectContext: roster.storage.mainThreadManagedObjectContext)
        if message.isChatMessageWithBody() {
            delegate?.xmppClient(sender, didReceiveMessage: message, from: user!)
        } else if let _ = message.forName("composing") {
            delegate?.xmppClient(sender, userIsComposing: user!)
        }
    }
}

extension XMPPDefaultClient: XMPPClientConnectionDelegate {
    public func xmppConnectionDidAuthenticate(_ sender: XMPPStream) {
        //TODO: initiate retrieval of archives from server
    }
}
