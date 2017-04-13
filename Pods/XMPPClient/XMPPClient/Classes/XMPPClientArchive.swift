//
//  XMPPClientArchive.swift
//  Pods
//
//  Created by Ali Gangji on 6/18/16.
//
//

import Foundation
import CoreData
import JSQMessagesViewController
import XMPPFramework

open class XMPPClientArchive: NSObject {
    
    open lazy var storage: XMPPMessageArchivingCoreDataStorage = {
       return XMPPMessageArchivingCoreDataStorage.sharedInstance()
    }()
    
    open lazy var archive: XMPPMessageArchiving = {
        let archive = XMPPMessageArchiving(messageArchivingStorage: self.storage)!
        archive.clientSideMessageArchivingOnly = true
        return archive
    }()
    
    var connection:XMPPClientConnection!
    
    open func setup(_ connection:XMPPClientConnection) {
        self.connection = connection
        connection.activate(archive)
        connection.getStream().addDelegate(self, delegateQueue: DispatchQueue.main)
    }
    
    open func teardown() {
        archive.deactivate()
    }
    
    open func messagesForJID(_ jid: String, inThread thread: String) -> [Any] {
        let moc = storage.mainThreadManagedObjectContext!
        let entityDescription = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: moc)
        let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>()
        let predicateFormat = "bareJidStr like %@ ANd thread like %@"
        let predicate = NSPredicate(format: predicateFormat, jid, thread)
        let retrievedMessages = NSMutableArray()
        var sortedRetrievedMessages = [Any]()
        
        request.predicate = predicate
        request.entity = entityDescription
        
        do {
            let results = try moc.fetch(request)
            
            for message in results {
                var element: DDXMLElement!
                do {
                    element = try DDXMLElement(xmlString: message.messageStr)
                } catch _ {
                    element = nil
                }
                
                let body: String
                let sender: String
                let date: Date
                
                date = message.timestamp
                
                if message.body != nil {
                    body = message.body
                } else {
                    body = ""
                }
                
                if element.attributeStringValue(forName: "to") == jid {
                    let displayName = connection.getStream().myJID
                    sender = displayName!.bare()
                } else {
                    sender = jid
                }
                
                let fullMessage = JSQMessage(senderId: sender, senderDisplayName: sender, date: date, text: body)
                retrievedMessages.add(fullMessage)
                
                
                let descriptor:NSSortDescriptor = NSSortDescriptor(key: "date", ascending: true);
                
                sortedRetrievedMessages = (retrievedMessages as NSArray).sortedArray(using: [descriptor]);
                
            }
        } catch _ {
            //catch fetch error here
        }
        return sortedRetrievedMessages
    }
    
    open func deleteMessages(_ messages: NSArray) {
        messages.enumerateObjects(using: { (message, idx, stop) -> Void in
            let moc = self.storage.mainThreadManagedObjectContext
            let entityDescription = NSEntityDescription.entity(forEntityName: "XMPPMessageArchiving_Message_CoreDataObject", in: moc!)
            let request = NSFetchRequest<XMPPMessageArchiving_Message_CoreDataObject>()
            let predicateFormat = "messageStr like %@ "
            let predicate = NSPredicate(format: predicateFormat, message as! String)
            
            request.predicate = predicate
            request.entity = entityDescription
            
            do {
                let results = try moc?.fetch(request)
                
                for message in results! {
                    var element: DDXMLElement!
                    do {
                        element = try DDXMLElement(xmlString: message.messageStr)
                    } catch _ {
                        element = nil
                    }
                    
                    if element.attributeStringValue(forName: "messageStr") == message as! String {
                        moc?.delete(message as! NSManagedObject)
                    }
                }
            } catch _ {
                //catch fetch error here
            }
        })
    }
    
    open func clearArchive() {
        deleteEntities("XMPPMessageArchiving_Message_CoreDataObject", fromMoc:storage.mainThreadManagedObjectContext)
        deleteEntities("XMPPMessageArchiving_Contact_CoreDataObject", fromMoc:storage.mainThreadManagedObjectContext)
    }
    
    fileprivate func deleteEntities(_ entity:String, fromMoc moc:NSManagedObjectContext) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: entity, in: moc)
        fetchRequest.includesPropertyValues = false
        do {
            if let results = try moc.fetch(fetchRequest) as? [NSManagedObject] {
                for result in results {
                    moc.delete(result)
                }
                
                try moc.save()
            }
        } catch {
            print("failed to clear core data")
        }
    }
}

extension XMPPClientArchive: XMPPStreamDelegate {
    public func xmppStream(_ sender: XMPPStream!, didReceive iq: XMPPIQ!) -> Bool {
        print("got iq \(iq)")
        //TODO: complete retrieval of archives from server
        return false
    }
}
