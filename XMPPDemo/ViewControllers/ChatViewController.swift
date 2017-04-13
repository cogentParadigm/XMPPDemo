//
//  ChatViewController.swift
//  XMPPDraft
//
//  Created by Ali Gangji on 4/11/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPFramework
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController, ContactPickerDelegate {
    var recipient: XMPPUserCoreDataStorageObject?
    var firstTime = true
    
    var messages = [JSQMessage]()
    
    let coordinator:MessagingCoordinator
    
    init(coordinator:MessagingCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = coordinator.client.connection.getStream().myJID.bare()
        self.senderDisplayName = coordinator.client.connection.getStream().myJID.bare()
        self.inputToolbar!.contentView!.leftBarButtonItem!.isHidden = true
        self.collectionView!.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let recipient = recipient {
            navigationItem.rightBarButtonItems = []
            navigationItem.title = recipient.displayName
            self.messages = coordinator.client.archive.messagesForJID(recipient.jidStr, inThread: "default") as! [JSQMessage]
            self.collectionView?.reloadData()
        } else {
            navigationItem.title = "New message"
            navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target:self, action: #selector(addRecipient)), animated: true)
            if firstTime {
                firstTime = false
                addRecipient()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coordinator.closeChat()
    }
    
    func addRecipient() {
        let controller = controllers.createContactListController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        self.recipient = recipient
        navigationItem.title = recipient.displayName
        //load archived messages and replace self.messages
        //messages = OneMessage.sharedInstance.loadArchivedMessagesFrom(jid: recipient.jidStr, thread:"default")
        finishReceivingMessage(animated: true)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return self.messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource? {
        let message: JSQMessage = self.messages[indexPath.item]
        
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        let outgoingBubbleImageData = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        let incomingBubbleImageData = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
        
        if message.senderId == self.senderId {
            return outgoingBubbleImageData
        }
        
        return incomingBubbleImageData
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let message: JSQMessage = self.messages[indexPath.item]
        
        if message.senderId == self.senderId {
            if let photoData = coordinator.client.vcard.avatar.photoData(for: coordinator.client.connection.getStream().myJID) {
                let senderAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: photoData), diameter: 30)
                return senderAvatar
            } else {
                var initials = ""
                for part in senderDisplayName.components(separatedBy:" ") {
                    if let initial = part.characters.first {
                        initials.append(initial)
                    }
                }
                let senderAvatar = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont(name: "Helvetica Neue", size: 14.0), diameter: 30)
                return senderAvatar
            }
        } else {
            if let photoData = coordinator.client.vcard.avatar.photoData(for: recipient!.jid!) {
                let recipientAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: photoData), diameter: 30)
                return recipientAvatar
            } else {
                var initials = ""
                for part in recipient!.displayName.components(separatedBy:" ") {
                    if let initial = part.characters.first {
                        initials.append(initial)
                    }
                }
                let recipientAvatar = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont(name: "Helvetica Neue", size: 14.0)!, diameter: 30)
                return recipientAvatar
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString? {
        if indexPath.item % 3 == 0 {
            let message: JSQMessage = self.messages[indexPath.item]
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil;
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString? {
        let message: JSQMessage = self.messages[indexPath.item]
        
        if message.senderId == self.senderId {
            return nil
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage: JSQMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == message.senderId {
                return nil
            }
        }
        
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
        return nil
    }
    
    // Mark: UICollectionView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let msg: JSQMessage = self.messages[indexPath.item]
        
        if !msg.isMediaMessage {
            if msg.senderId == self.senderId {
                cell.textView!.textColor = UIColor.black
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.black, NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
            } else {
                cell.textView!.textColor = UIColor.white
                cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName:UIColor.white, NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
            }
        }
        
        return cell
    }
    
    // Mark: JSQMessages collection view flow layout delegate
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        let currentMessage: JSQMessage = self.messages[indexPath.item]
        if currentMessage.senderId == self.senderId {
            return 0.0
        }
        
        if indexPath.item - 1 > 0 {
            let previousMessage: JSQMessage = self.messages[indexPath.item - 1]
            if previousMessage.senderId == currentMessage.senderId {
                return 0.0
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {
        return 0.0
    }
    
    func oneStream(sender: XMPPStream, didReceiveMessage message: XMPPMessage, from user: XMPPUserCoreDataStorageObject) {
        if message.isChatMessageWithBody() {
            JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
            
            if let msg: String = message.forName("body")?.stringValue {
                if let from: String = message.attribute(forName: "from")?.stringValue {
                    let message = JSQMessage(senderId: from, senderDisplayName: from, date: Date(), text: msg)
                    messages.append(message!)
                    
                    self.finishReceivingMessage(animated: true)
                }
            }
        }
    }
    
    func oneStream(sender: XMPPStream, userIsComposing user: XMPPUserCoreDataStorageObject) {
        self.showTypingIndicator = !self.showTypingIndicator
        self.scrollToBottom(animated: true)
    }
    
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        let fullMessage = JSQMessage(senderId: coordinator.client.connection.getStream().myJID.bare(), senderDisplayName: coordinator.client.connection.getStream().myJID.bare(), date: Date(), text: text)
        messages.append(fullMessage!)
        
        if let recipient = recipient {
            coordinator.client.sendMessage(text, thread: "default", to: recipient.jidStr) { stream, message in
                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                self.finishSendingMessage(animated: true)
            }
        }
    }
    
}
