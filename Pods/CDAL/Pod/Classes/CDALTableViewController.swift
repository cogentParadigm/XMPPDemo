//
//  CDALTableViewController.swift
//  Pods
//
//  Created by Ali Gangji on 5/18/16.
//
//

import UIKit
import CoreData

open class CDALTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    open var results:NSFetchedResultsController<NSFetchRequestResult>?
    open let context:NSManagedObjectContext
    
    public init(moc:NSManagedObjectContext) {
        context = moc
        super.init(style: .plain)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }
    
    open func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    open func configureCell(_ cell:UITableViewCell, indexPath:IndexPath) {
        //override to configure cell
    }
    
    open func query(_ cdQuery:CDALQuery, sectionKey:String?) {
        results = NSFetchedResultsController(fetchRequest: cdQuery.build(), managedObjectContext: context, sectionNameKeyPath: sectionKey, cacheName: nil)
        results!.delegate = self
        fetch()
    }
    
    open func fetch() {
        do {
            try results?.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    // MARK: - Table view data source
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = results?.sections {
            return sections.count
        }
        return 0
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = results?.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        
        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let insertIndexPath = newIndexPath {
                tableView.insertRows(at: [insertIndexPath], with: .fade)
            }
        case .delete:
            if let deleteIndexPath = indexPath {
                tableView.deleteRows(at: [deleteIndexPath], with: .fade)
            }
        case .update:
            if let updateIndexPath = indexPath, let cell = self.tableView.cellForRow(at: updateIndexPath) {
                configureCell(cell, indexPath: updateIndexPath)
            }
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [indexPath!], with: .fade)
        }
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }


}
