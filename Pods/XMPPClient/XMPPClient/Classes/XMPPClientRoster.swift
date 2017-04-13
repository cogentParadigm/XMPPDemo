//
//  XMPPClientRoster.swift
//  Pods
//
//  Created by Ali Gangji on 6/19/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientRoster: NSObject {
    
    open lazy var storage: XMPPClientRosterCoreDataStorage = {
        return XMPPClientRosterCoreDataStorage()
    }()
    
    open lazy var roster: XMPPRoster = {
        let roster = XMPPRoster(rosterStorage:self.storage)!
        roster.autoFetchRoster = true
        roster.autoAcceptKnownPresenceSubscriptionRequests = true
        roster.autoClearAllUsersAndResources = false
        roster.addDelegate(self, delegateQueue:DispatchQueue.main)
        return roster
    }()
    
    var connection:XMPPClientConnection!

    open func setup(_ connection:XMPPClientConnection) {
        self.connection = connection
        connection.activate(roster)
    }
    
    open func teardown() {
        roster.deactivate()
    }
    
    open func userForJID(_ jid: String) -> XMPPUserCoreDataStorageObject? {
        let userJID = XMPPJID(string:jid)
        if let user = storage.user(for: userJID, xmppStream: connection.getStream(), managedObjectContext: storage.mainThreadManagedObjectContext) {
            return user
        } else {
            return nil
        }
    }
    
    open func sendBuddyRequestTo(_ username: String) {
        let presence: DDXMLElement = DDXMLElement.element(withName: "presence") as! DDXMLElement
        presence.addAttribute(withName: "type", stringValue: "subscribe")
        presence.addAttribute(withName: "to", stringValue: username)
        presence.addAttribute(withName: "from", stringValue: connection.getStream().myJID.bare())
        connection.getStream().send(presence)
    }
    
    open func acceptBuddyRequestFrom(_ username: String) {
        let presence: DDXMLElement = DDXMLElement.element(withName: "presence") as! DDXMLElement
        presence.addAttribute(withName: "to", stringValue: username)
        presence.addAttribute(withName: "from", stringValue: connection.getStream().myJID.bare())
        presence.addAttribute(withName: "type", stringValue: "subscribed")
        connection.getStream().send(presence)
    }
    
    open func declineBuddyRequestFrom(_ username: String) {
        let presence: DDXMLElement = DDXMLElement.element(withName: "presence") as! DDXMLElement
        presence.addAttribute(withName: "to", stringValue: username)
        presence.addAttribute(withName: "from", stringValue: connection.getStream().myJID.bare())
        presence.addAttribute(withName: "type", stringValue: "unsubscribed")
        connection.getStream().send(presence)
    }

}

extension XMPPClientRoster: XMPPRosterDelegate {
    public func xmppRosterDidEndPopulating(sender: XMPPRoster?) {
        //let jidList = storage.jidsForXMPPStream(connection.connection.getStream())
        //print("List=\(jidList)")
        print("ROSTER POPULATED")
        
    }
}
