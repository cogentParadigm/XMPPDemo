//
//  CDALManager.swift
//  Pods
//
//  Created by Ali Gangji on 3/27/16.
//
//

import CoreData

public struct CDALNotificationType {
    static let StoreOpened = "CDALStoreOpened"
    static let StoreChanged = "CDALStoreChanged"
    static let UnhandledException = "CDALUnhandledException"
}

open class CDALManager: NSObject {

    let configuration:CDALConfigurationProtocol
    let alerts = CDALAlerts()
    
    var local:CDALBackendProtocol?
    var cloud:CDALCloudEnabledBackendProtocol?

    public init(configuration:CDALConfigurationProtocol) {
        self.configuration = configuration
    }
    
    convenience init(modelName:String) {
        self.init(configuration:CDALConfiguration(modelName:modelName))
    }
    
    //MARK: Property Setters
    open func setLocalBackend(_ backend:CDALBackendProtocol) {
        local = backend
    }
    
    open func setCloudBackend(_ backend:CDALCloudEnabledBackendProtocol) {
        cloud = backend
    }
    
    //MARK: Property Getters
    open func backend() -> CDALBackendProtocol {
        if configuration.isCloudEnabled() {
            return cloud!
        }
        return local!
    }
    open func mainContext() -> NSManagedObjectContext {
        return context
    }
    
    //MARK: Initialization Sequence
    open func setup(_ completion:(() -> Void)?) {
        if let available = cloud?.isAvailable() {
            configuration.setCloudAvailable(available)
        }
        configuration.update()
        
        //Do we have a saved preference?
        if configuration.isCloudPreferenceSelected() {
            initializePreferredBackend(completion)
        } else if configuration.isCloudAvailable() {
            //available but not selected - prompt to ask
            configuration.setFirstInstall(true)
            choosePreferredBackend(completion)
        } else {
            //not selected and not available
            initializeLocalBackend(completion)
        }
    }
    
    /**
     * Prompt the user to choose a preferred backend and initialize it
     */
    func choosePreferredBackend(_ completion:(() -> Void)?) {
        alerts.cloudPreference() { choice in
            if choice == 1 {
                self.configuration.shouldUseCloud(false)
                self.initializeLocalBackend(completion)
            } else {
                self.configuration.shouldUseCloud(true)
                self.initializeCloudBackend(completion)
            }
        }
    }
    
    /**
     * Initialize a backend based on the users saved preference
     */
    func initializePreferredBackend(_ completion:(() -> Void)?) {
        if configuration.shouldUseCloud() {
            //user chose to use cloud
            if configuration.isCloudAvailable() {
                //enable cloud
                initializeCloudBackend(completion)
            } else {
                ///The cloud connection is no longer available
                
                //alert them we are switching to local storage, and
                //clear saved preference so they are prompted next time
                configuration.clearCloudPreference()
                //prompt user that they should sign in
                alerts.cloudSignout() { _ in
                    self.initializeLocalBackend(completion)
                }
            }
        } else {
            //user chose local only
            if configuration.isCloudAvailable() && cloudStoreExists() && !localStoreExists() {
                //prompt about migration
                alerts.cloudDisabled() { choice in
                    if choice == 1 {
                        self.configuration.shouldUseCloud(true)
                        self.initializeCloudBackend(completion)
                    } else if choice == 2 {
                        //keep data
                        self.configuration.shouldMigrateData(true)
                        self.initializeLocalBackend(completion)
                    } else if choice == 3 {
                        //delete data
                        self.configuration.shouldMigrateData(false)
                        self.initializeLocalBackend(completion)
                    }
                }
            } else {
                initializeLocalBackend(completion)
            }
        }
    }
    
    func initializeLocalBackend(_ completion:(() -> Void)?) {
        configuration.setCloudEnabled(false)
        self.createStack(completion)
    }
    
    func initializeCloudBackend(_ completion:(() -> Void)?) {
        configuration.setCloudEnabled(true)
        cloud?.authenticate() { changed in
            if changed {
                self.alerts.cloudSignout() {
                    self.createStack(completion)
                }
            } else {
                self.createStack(completion)
            }
        }
    }
    
    fileprivate func migrateDataIfRequired(_ completion:@escaping () -> Void) {
        if (configuration.isCloudEnabled()) {
            //using cloud
            if (localStoreExists()) {
                if (cloudStoreExists()) {
                    //prompt about merge
                    alerts.cloudMerge() { choice in
                        if choice == 1 {
                            //merge
                            if (self.migrate(self.local!, destination: self.cloud!, shouldDelete: true, shouldBackup: true)) {
                                self.configuration.hasJustMigrated(true)
                            }
                            completion()
                        } else if choice == 2 {
                            //don't merge
                            completion()
                        }
                    }
                } else {
                    if (migrate(local!, destination: cloud!, shouldDelete: true, shouldBackup: true)) {
                        configuration.hasJustMigrated(true)
                    }
                    completion()
                }
            } else {
                //using cloud but no local store to migrate
                completion()
            }
        } else {
            //using local
            if (!configuration.isFirstInstall() && cloudStoreExists()) {
                if (configuration.shouldMigrateData()) {
                    if (localStoreExists()) {
                        if (migrate(cloud!, destination: local!, shouldDelete:true, shouldBackup: true)) {
                            configuration.hasJustMigrated(true)
                        }
                    } else {
                        //not prompting about merge
                    }
                } else {
                    cloud?.delete()
                    deregisterForStoreChanges()
                }
            }
            completion()
        }
    }
    
    func createStack(_ completion:(() -> Void)?) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            
            self.migrateDataIfRequired() { Void in
                self.open(completion)
                self.configuration.setFirstInstall(false)
            }
            
        })
    }
    
    //MARK: - OPERATIONS
    func open(_ completion:(() -> Void)?) {
        if configuration.isStoreOpen() {
            completion?()
            return
        }
        configuration.isStoreOpening(true)
        registerForStoreChanges(coordinator)
        do {
            try backend().addToCoordinator(coordinator)
            configuration.isStoreOpening(false)
            configuration.isStoreOpen(true)
            completion?()
            postStoreOpenedNotification()
        } catch {
            completion?()
        }
    }
    
    open func migrate(_ source:CDALBackendProtocol, destination:CDALBackendProtocol, shouldDelete:Bool, shouldBackup:Bool) -> Bool {
        if (shouldBackup && source.storeExists()) {
            saveBackup(source)
        }
        
        let coordinator = createCoordinator()
        let sourceStore:NSPersistentStore?
        
        do {
            sourceStore = try source.addToCoordinator(coordinator)
        } catch _ {
            sourceStore = nil
        }
        
        if (sourceStore == nil) {
            return false
        } else {
            let newStore:NSPersistentStore?
            do {
                newStore = try destination.migrateStore(sourceStore!, coordinator: coordinator)
            } catch _ {
                newStore = nil
            }
            
            if (newStore != nil) {
                deregisterForStoreChanges()
                if (shouldDelete) {
                    destination.delete()
                }
                return true
            } else {
                return false
            }
        }
    }
    
    // MARK: - MODEL
    lazy var model: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.configuration.getModelName(), withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    // MARK: - CONTEXT
    lazy var parentContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.coordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var context: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.mainQueueConcurrencyType)
        moc.parent = self.parentContext
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var importContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.parent = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var sourceContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.parent = self.context
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    lazy var seedContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = self.seedCoordinator
        moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return moc
    }()
    
    // MARK: - COORDINATOR
    lazy var coordinator: NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    lazy var sourceCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    lazy var seedCoordinator:NSPersistentStoreCoordinator = {
        return NSPersistentStoreCoordinator(managedObjectModel:self.model)
    }()
    
    //MARK: - HELPERS
    fileprivate func localStoreExists() -> Bool {
        if let exists = local?.storeExists() {
            return exists
        }
        return false
    }
    
    fileprivate func cloudStoreExists() -> Bool {
        if let exists = cloud?.storeExists() {
            return exists
        }
        return false
    }
    
    /**
     * Creates a backup of the specified backend
     * @return Returns YES of file was migrated or NO if not.
     */
    fileprivate func saveBackup(_ backend:CDALBackendProtocol) -> Bool {
        return backend.saveBackup(createCoordinator())
    }
    
    fileprivate func createCoordinator() -> NSPersistentStoreCoordinator {
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        return coordinator
    }
    
    fileprivate func registerForStoreChanges(_ storeCoordinator: NSPersistentStoreCoordinator) {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(storesWillChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: storeCoordinator)
        nc.addObserver(self, selector: #selector(storesDidChange(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: storeCoordinator)
        nc.addObserver(self, selector: #selector(storesDidImport(_:)), name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object: storeCoordinator)
    }
    
    fileprivate func deregisterForStoreChanges() {
        let nc = NotificationCenter.default
        nc.removeObserver(self,  name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object:nil)
        nc.removeObserver(self, name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object:nil)
        nc.removeObserver(self, name: NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges, object:nil)
        
    }
    
    fileprivate func postStoreOpenedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: CDALNotificationType.StoreOpened),
                object:self)
    }
    
    fileprivate func postStoreChangedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: CDALNotificationType.StoreChanged),
                object:self)
    }
    
    func storesWillChange(_ n:Notification) {
        self.sourceContext.performAndWait {
            do {
                try self.sourceContext.save()
                self.sourceContext.reset()
            } catch {print("ERROR saving sourceContext \(self.sourceContext.description) - \(error)")}
        }
        self.importContext.performAndWait {
            do {
                try self.importContext.save()
                self.importContext.reset()
            } catch {print("ERROR saving importContext \(self.importContext.description) - \(error)")}
        }
        self.context.performAndWait {
            do {
                try self.context.save()
                self.context.reset()
            } catch {print("ERROR saving context \(self.context.description) - \(error)")}
        }
        self.parentContext.performAndWait {
            do {
                try self.parentContext.save()
                self.parentContext.reset()
            } catch {print("ERROR saving parentContext \(self.parentContext.description) - \(error)")}
        }
    }
    
    func storesDidChange(_ n:Notification) {
        postStoreChangedNotification()
    }
    
    func storesDidImport(_ n:Notification) {
        self.context.mergeChanges(fromContextDidSave: n)
        self.postStoreChangedNotification()
    }
}
