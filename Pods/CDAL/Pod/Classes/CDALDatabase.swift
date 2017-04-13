//
//  CDALDatabase.swift
//  Pods
//
//  Created by Ali Gangji on 4/28/16.
//
//
import CoreData

open class CDALDatabase: NSObject {
    
    let context:NSManagedObjectContext
    
    public init(context:NSManagedObjectContext) {
        self.context = context
    }
    
    open func create<EntityType: NSManagedObject>() -> EntityType {
        let item = NSEntityDescription.insertNewObject(forEntityName: "\(EntityType.self)", into: context) as! EntityType
        return item
    }
    open func create(_ entity:String) -> NSManagedObject {
        let item = NSEntityDescription.insertNewObject(forEntityName: entity, into: context)
        return item
    }
    // MARK: - QUERY
    open func query(_ entityName:String) -> CDALQuery {
        return CDALQuery(entityName: entityName)
    }
    // MARK: - FETCH
    open func fetch<EntityType: NSManagedObject>(_ request:NSFetchRequest<NSFetchRequestResult>) -> [EntityType]? {
        let entity = NSEntityDescription.entity(forEntityName: "\(EntityType.self)".components(separatedBy: ".").last!, in: context)
        request.entity = entity
        return (try? context.fetch(request)) as? [EntityType]
    }
    open func fetch(_ request:NSFetchRequest<NSFetchRequestResult>) -> [NSManagedObject]? {
        return (try? context.fetch(request)) as? [NSManagedObject]
    }
    open func fetch<EntityType: NSManagedObject>(_ query:CDALQuery) -> [EntityType]? {
        return fetch(query.build())
    }
    
    // MARK: - SAVING
    open func save() {
        saveContext(context)
    }
    open func save(_ object:NSManagedObject) {
        faultObject(object, moc: context)
    }
    open func saveContext(_ moc:NSManagedObjectContext) {
        moc.performAndWait {
            
            if moc.hasChanges {
                
                do {
                    try moc.save()
                    //print("SAVED context \(moc.description)")
                } catch {
                    print("ERROR saving context \(moc.description) - \(error)")
                }
            } else {
                //print("SKIPPED saving context \(moc.description) because there are no changes")
            }
            if let parentContext = moc.parent {
                self.saveContext(parentContext)
            }
        }
    }
    open func faultObject(_ object:NSManagedObject, moc:NSManagedObjectContext) {
        moc.performAndWait {
            if object.hasChanges {
                self.saveContext(moc)
            }
            if object.isFault == false {
                moc.refresh(object, mergeChanges: false)
            }
            if let parentMoc = moc.parent {
                self.faultObject(object, moc: parentMoc)
            }
        }
    }
}
