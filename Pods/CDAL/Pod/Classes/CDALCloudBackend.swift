//
//  CDALCloudBackend.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

import CoreData

open class CDALCloudBackend: NSObject, CDALCloudEnabledBackendProtocol {
    
    fileprivate struct Constants {
        static let appID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? NSString
        static let iCloudContainerID = "iCloud.\(Constants.appID)"
        static let ubiquityContainerKey = ".\(Constants.appID).ubiquityContainerID"
        static let ubiquityTokenKey = ".\(Constants.appID).ubiquityToken"
    }
    
    var ubiquityContainerID: NSString? = Constants.iCloudContainerID as NSString?
    var hasCheckedCloud = false
    var cloudFileExists = false
    var rebuildFromCloud = false
    
    let name:String
    
    public init(name:String) {
        self.name = name
        super.init()
    }
    
    open func isAvailable() -> Bool {
        if let _ = FileManager.default.ubiquityIdentityToken {
            return true
        }
        else {
            return false
        }
    }
    open func storeExists() -> Bool {
        // if iCloud container is not available just return NO
        if (!isAvailable()) {
            return false
        }
        
        if let path = containerURL()?.path {
            var _: Bool = FileManager.default.fileExists(atPath: path)
        }

        // This may block for some time if a _query has not returned results yet
        let icloudFileExists: Bool = doesICloudFileExist()
        
        return icloudFileExists
    }
    
    open func getStoreName() -> String {
        return name
    }
    
    open func authenticate(_ completion:((Bool) -> Void)?) {
        if ubiquitousTokenHasChanged() {
            completion?(true)
        } else {
            completion?(false)
        }
        storeToken()
    }
    

    open func storeOptions() -> NSDictionary {
        
        var options: NSDictionary
        
        if (rebuildFromCloud) {
            options = [NSPersistentStoreUbiquitousContentNameKey:name,
                       NSPersistentStoreRebuildFromUbiquitousContentOption:true,
                       NSMigratePersistentStoresAutomaticallyOption:true,
                       NSInferMappingModelAutomaticallyOption:true,
                       NSSQLitePragmasOption:["journal_mode" : "DELETE" ]]
            rebuildFromCloud = false
        } else {
            options = [NSPersistentStoreUbiquitousContentNameKey:name,
                       NSMigratePersistentStoresAutomaticallyOption:true,
                       NSInferMappingModelAutomaticallyOption:true,
                       NSSQLitePragmasOption:["journal_mode" : "DELETE" ]]
        }
        
        return options
    }
    
    open func delete() {
        var result:Bool = false
        do {
            try NSPersistentStoreCoordinator.removeUbiquitousContentAndPersistentStore(at: storeURL() as URL,
                                                                                            options:(storeOptions() as! [AnyHashable: Any]))
            result = true
        } catch  {
            result = false
        }
        
        if (!result) {
            return
        } else {
            deleteStoreFile(documentsDirectory().appendingPathComponent("CoreDataUbiquitySupport"))
        }
    }
    
    fileprivate func storeToken() {
        if let token:(NSCoding & NSCopying & NSObjectProtocol)? = FileManager.default.ubiquityIdentityToken {
            // Write the ubquity identity token to NSUserDefaults if it exists.
            // Otherwise, remove the key.
            if let tk = token {
                let newTokenData: Data = NSKeyedArchiver.archivedData(withRootObject: tk)
                UserDefaults.standard.set(newTokenData, forKey:Constants.ubiquityTokenKey)
            }
        }
        else {
            UserDefaults.standard.removeObject(forKey: Constants.ubiquityTokenKey)
        }
    }
    
    fileprivate func containerURL() -> URL? {
        if let iCloudURL:URL = FileManager.default.url(forUbiquityContainerIdentifier: ((ubiquityContainerID as! String))) {
            return iCloudURL.appendingPathComponent("CoreData").appendingPathComponent(name)
        }
        else {
            return nil
        }
    }
    
    fileprivate func doesICloudFileExist() -> Bool {
        var count: Int  = 0
        
        // Start with 10ms time boxes
        let ti: TimeInterval  = 2.0
        
        // Wait until delegate did callback
        while (!hasCheckedCloud) {
            //has not checked iCloud yet, waiting
            let date: Date = Date(timeIntervalSinceNow: ti)
            // Let the current run-loop do it's magif for one time-box.
            RunLoop.current.run(mode: RunLoopMode.commonModes, before: date)
            // Double the time box, for next try, max out at 1000ms.
            //ti = MIN(1.0, ti * 2);
            count = count + 1
            if (count>10) {
                //given up waiting
                hasCheckedCloud = true
                cloudFileExists = true
            }
        }
        
        if (hasCheckedCloud) {
            if (cloudFileExists) {
                hasCheckedCloud = false
                return true
            } else {
                hasCheckedCloud = false
                return false
            }
        } else {
            return false
        }
    }
    

    fileprivate func ubiquitousTokenHasChanged() -> Bool {
        
        let activeToken = FileManager.default.ubiquityIdentityToken
        
        if let oldTokenData: Data = UserDefaults.standard.object(forKey: Constants.ubiquityTokenKey) as? Data {
            
            if let oldToken: NSCoding & NSCopying & NSObjectProtocol = NSKeyedUnarchiver.unarchiveObject(with: oldTokenData) as? NSCoding & NSCopying & NSObjectProtocol {
                
                if (!oldToken.isEqual(activeToken)) {
                    return true
                }
            }
        }
        return false
    }
}
