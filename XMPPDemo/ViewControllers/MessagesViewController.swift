//
//  MessagesViewController.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import CDAL
import CoreData
import XMPPFramework
import JSQMessagesViewController

class MessagesViewController: CDALTableViewController, ContactPickerDelegate {
    
    var users = [XMPPUserCoreDataStorageObject]()
    var messages = [String]()
    var times = [Date]()
    let coordinator:MessagingCoordinator
    
    lazy var add:UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newMessage))
    }()
    
    init(coordinator:MessagingCoordinator) {
        self.coordinator = coordinator
        super.init(moc:coordinator.client.archive.storage.mainThreadManagedObjectContext)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Messages"
        
        //query the message archive and sort by timestamp
        let q = CDALQuery(entityName: "XMPPMessageArchiving_Message_CoreDataObject")
        q.sort("timestamp", ascending: false)
        query(q, sectionKey: "bareJidStr")
        populate()
        
        navigationItem.rightBarButtonItems = [add]
    }
    
    func populate() {
        //print("\(coordinator.unreadCount()) unread messages")
        if let messages = results?.fetchedObjects {
            for message in messages {
                if let message = message as? XMPPMessageArchiving_Message_CoreDataObject, let user = coordinator.client.roster.userForJID(message.bareJidStr) {
                    if !users.contains(user) {
                        if let vcard = coordinator.client.vcard.temp.vCardTemp(for: user.jid, shouldFetch: true) {
                            if let nickname = vcard.nickname {
                                user.displayName = nickname
                            }
                        }
                        //print("\(user.unreadMessages) unread messages from \(user.displayName)")
                        users.append(user)
                        self.messages.append(message.body)
                        self.times.append(message.timestamp)
                    }
                }
            }
        }
    }
    
    override func configureTableView() {
        tableView.register(MessagesTableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.rowHeight = 60
    }
    
    override func configureCell(_ cell: UITableViewCell, indexPath: IndexPath) {
        let c = cell as! MessagesTableViewCell
        let user = users[indexPath.row]
        let msg = messages[indexPath.row]
        let time = times[indexPath.row]
        c.primaryLabel.text = user.displayName
        c.secondaryLabel.text = msg
        
        let calendar = NSCalendar.current
        let formatter = DateFormatter()
        if calendar.isDateInToday(time) {
            formatter.dateFormat = "h:mma"
            c.rightLabel.text = formatter.string(from: time)
        } else if calendar.isDateInYesterday(time) {
            c.rightLabel.text = "Yesterday"
        } else {
            let date1 = calendar.startOfDay(for: time)
            let date2 = calendar.startOfDay(for: Date(timeIntervalSinceNow: 0))
            let components = calendar.dateComponents([.day], from: date1, to: date2)
            if components.day! < 7 {
                formatter.dateFormat = "EEEE"
            } else {
                formatter.dateFormat = "M/d/yy"
            }
            c.rightLabel.text = formatter.string(from: time)
        }
        
        if Int(user.unreadMessages) > 0 {
            c.markUnread()
        }
        
        if user.photo != nil {
            c.photoView.image = JSQMessagesAvatarImageFactory.avatarImage(with: user.photo, diameter: 30).avatarImage
        } else {
            if let photoData = coordinator.client.vcard.avatar.photoData(for: user.jid) {
                cell.imageView!.image = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: photoData), diameter: 30).avatarImage
            } else {
                var initials = ""
                for part in user.displayName.components(separatedBy:" ") {
                    if let initial = part.characters.first {
                        initials.append(initial)
                    }
                }
                c.photoView.image = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: UIColor(white: 0.85, alpha: 1.0), textColor: UIColor(white: 0.60, alpha: 1.0), font: UIFont(name: "Helvetica Neue", size: 14.0)!, diameter: 30).avatarImage
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! MessagesTableViewCell
        cell.markRead()
        let controller = controllers.createChatViewController(user: users[indexPath.row])
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func newMessage() {
        let controller = controllers.createContactListController()
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject) {
        let controller = controllers.createChatViewController(user: recipient)
        navigationController?.setViewControllers([self, controller], animated: true)
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    override func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //do nothing
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        //do nothing
    }
    
    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //do nothing
    }
    
    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        users.removeAll()
        messages.removeAll()
        times.removeAll()
        populate()
        tableView.reloadData()
    }
}
