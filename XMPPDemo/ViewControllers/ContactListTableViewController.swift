//
//  ContactListTableViewController.swift
//  XMPPDraft
//
//  Created by Ali Gangji on 4/11/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit
import XMPPFramework
import CDAL

protocol ContactPickerDelegate {
    func didSelectContact(recipient: XMPPUserCoreDataStorageObject)
}

class ContactListTableViewController: CDALTableViewController {
    
    let coordinator:MessagingCoordinator
    var delegate:ContactPickerDelegate?
    
    init(coordinator:MessagingCoordinator) {
        self.coordinator = coordinator
        super.init(moc:coordinator.client.roster.storage.mainThreadManagedObjectContext)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "New Message"
        //query the message archive and sort by timestamp
        let q = CDALQuery(entityName: "XMPPUserCoreDataStorageObject")
            .sort("sectionNum", ascending: true)
            .sort("displayName", ascending: true)
        query(q, sectionKey: "sectionNum")
    }
    
    override func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.rowHeight = 50.0
    }
    
    override func configureCell(_ cell:UITableViewCell, indexPath:IndexPath) {
        let user = results?.object(at: indexPath) as! XMPPUserCoreDataStorageObject
        
        cell.textLabel!.text = user.displayName;
        
        if user.unreadMessages.intValue > 0 {
            cell.backgroundColor = .orange
        } else {
            cell.backgroundColor = .white
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections = results!.sections
        
        if section < sections!.count {
            let sectionInfo: AnyObject = sections![section]
            let tmpSection: Int = Int(sectionInfo.name)!
            
            switch (tmpSection) {
            case 0 :
                return "Available"
                
            case 1 :
                return "Away"
                
            default :
                return "Offline"
                
            }
        }
        
        return ""
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = results?.object(at: indexPath) as! XMPPUserCoreDataStorageObject
        delegate?.didSelectContact(recipient: user)
    }
    
}
