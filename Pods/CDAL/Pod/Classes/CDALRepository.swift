//
//  CDALRepository.swift
//  Pods
//
//  Created by Ali Gangji on 4/29/16.
//
//
import CoreData

open class CDALRepository<EntityType: NSManagedObject>: NSObject {
    let db:CDALDatabase
    let items = [EntityType]()
    public init(db:CDALDatabase) {
        self.db = db
    }
    /**
     * Create a new record. This will not be saved
     */
    open func create() -> EntityType {
        return db.create()
    }
    /**
     * create a new record and set some attributes. This will not be saved
     */
    open func create(_ attributes:[String:AnyObject]) -> EntityType {
        let item:EntityType = db.create()
        for (key, value) in attributes {
            (item as NSManagedObject).setValue(value, forKey: key)
        }
        return item
    }
    /**
     * Save and fault a record
     */
    open func save(_ object:NSManagedObject) {
        db.save(object)
    }
    /**
     * fetch records
     */
    open func query(_ request:NSFetchRequest<NSFetchRequestResult>) -> [EntityType]? {
        return db.fetch(request)
    }
}
