//
//  CDALBackendProtocol.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//
import CoreData

public protocol CDALBackendProtocol {
    func isAvailable() -> Bool
    func storeExists() -> Bool
    func getStoreName() -> String
    func documentsDirectory() -> URL
    func storeURL() -> URL
    func storeOptions() -> NSDictionary
    func addToCoordinator(_ coordinator:NSPersistentStoreCoordinator) throws -> NSPersistentStore
    func migrateStore(_ source:NSPersistentStore, coordinator:NSPersistentStoreCoordinator) throws -> NSPersistentStore
    func delete()
}

public protocol CDALCloudEnabledBackendProtocol: CDALBackendProtocol {
    func authenticate(_ completion:((Bool) -> Void)?)
}

public extension CDALBackendProtocol {
    func isAvailable() -> Bool {
        return true
    }
    func documentsDirectory() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as URL
    }
    func storeURL() -> URL {
        return documentsDirectory().appendingPathComponent(getStoreName()).appendingPathExtension("sqlite")
    }
    func storeOptions() -> NSDictionary {
        return [NSMigratePersistentStoresAutomaticallyOption:true,
                NSInferMappingModelAutomaticallyOption:true,
                NSSQLitePragmasOption:["journal_mode" : "DELETE"]]
    }
    func storeExists() -> Bool {
        var isDir: ObjCBool = false
        let url = storeURL()
        let fileExists: Bool = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return fileExists
    }
    func addToCoordinator(_ coordinator: NSPersistentStoreCoordinator) throws -> NSPersistentStore {
        let store: NSPersistentStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL(), options: (storeOptions() as! [AnyHashable: Any]))
        return store
    }
    func migrateStore(_ source:NSPersistentStore, coordinator: NSPersistentStoreCoordinator) throws -> NSPersistentStore {
        let store: NSPersistentStore = try coordinator.migratePersistentStore(source, to:storeURL(), options:(storeOptions() as! [AnyHashable: Any]), withType:NSSQLiteStoreType)
        return store
    }
    func saveBackup(_ coordinator:NSPersistentStoreCoordinator) -> Bool {
        do {
            let source: NSPersistentStore = try addToCoordinator(coordinator)
            let destination: NSPersistentStore?
            do {
                destination = try coordinator.migratePersistentStore(source, to:backupStoreURL(), options:(storeOptions() as! [AnyHashable: Any]), withType:NSSQLiteStoreType)
            } catch {
                destination = nil
            }
            
            if (destination != nil) {
                return true
            } else {
                return false
            }
        } catch  {
            return false
        }
    }
    func backupStoreURL() -> URL {
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmssSSS"
        
        let dateString: String = dateFormatter.string(from: Date())
        
        
        let fileName = getStoreName() + "_Backup_" + dateString
        
        return documentsDirectory().appendingPathComponent(fileName as String).appendingPathExtension("sqlite")
    }
    func delete() {
        deleteStoreFile(storeURL())
    }
    func deleteStoreFile(_ fileURL:URL) {
        if (!FileManager.default.fileExists(atPath: fileURL.path)) {
            return
        }
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            let fileCoordinator:NSFileCoordinator = NSFileCoordinator()
            var error: NSError? = nil
            fileCoordinator.coordinate(writingItemAt: fileURL, options: NSFileCoordinator.WritingOptions.forDeleting, error: &error, byAccessor: {writingURL in
                let fileManager:FileManager = FileManager()
                do {
                    try fileManager.removeItem(at: writingURL)
                } catch {
                    fatalError()
                }
            })
            
        })
    }
}
