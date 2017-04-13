//
//  CDALDeviceManager.swift
//  Pods
//
//  Created by Ali Gangji on 4/13/16.
//
//

open class CDALDeviceManager: NSObject {
    fileprivate struct Constants {
        static let appID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? NSString
        static let iCloudUUIDKey = ".\(Constants.appID).iCloudUUID"
    }
    
    var uuids = [String]()
    var deviceList:CDALDeviceList?
    var deviceListName = "CDALKnownDevices.plist"
    var query:NSMetadataQuery?
    
    let backgroundQueue = DispatchQueue(label: "CDALDeviceManager.BackgroundQueue", attributes: [])
    
    public override init() {
        super.init()
        if ((UserDefaults.standard.object(forKey: Constants.iCloudUUIDKey) as? String) == nil) {
            UserDefaults.standard.set(UUID().uuidString, forKey: Constants.iCloudUUIDKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func getDeviceID() -> String {
        return UserDefaults.standard.object(forKey: Constants.iCloudUUIDKey) as! String
    }
    
    func setup() {
        uuids.removeAll()
        deviceList = CDALDeviceList(url: deviceListURL(), queue: OperationQueue())
        NSFileCoordinator.addFilePresenter(deviceList!)
        query = NSMetadataQuery()
        query?.searchScopes = [NSMetadataQueryUbiquitousDataScope]
        query?.predicate = NSPredicate(format: "%K LIKE %@", argumentArray: [NSMetadataItemFSNameKey, deviceListName])
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(deviceListChanged(_:)), name: NSNotification.Name.NSMetadataQueryDidUpdate, object: query!)
        DispatchQueue.main.async {
            self.query?.start()
        }
    }
    
    func teardown() {
        if deviceList != nil {
            NSFileCoordinator.removeFilePresenter(deviceList!)
            deviceList = nil
            uuids.removeAll()
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: self.query!)
            DispatchQueue.main.async {
                self.query?.stop()
                self.query = nil
            }
        }
    }
    
    func deviceListChanged(_ notification:Notification) {
        backgroundQueue.async {
            self.query?.disableUpdates()
            self.refreshDeviceList(false) { deviceListExisted, currentDevicePresent in
                self.query?.enableUpdates()
            }
        }
    }
    
    func refreshDeviceList(_ canAddCurrentDevice:Bool, completion:@escaping (_ deviceListExisted:Bool, _ currentDevicePresent:Bool) -> Void) {
        uuids.removeAll()
        let uuid = UserDefaults.standard.string(forKey: Constants.iCloudUUIDKey)!
        
        download(deviceListURL(), dispatchQueue: backgroundQueue) { syncCompleted, error in
            var err:NSError? = nil
            let coordinator = NSFileCoordinator(filePresenter: self.deviceList)
            var deviceListExisted = false
            var currentDevicePresent = false
            coordinator.coordinate(readingItemAt: self.deviceListURL(), options: .withoutChanges, error: &err) { url in
                let dict = NSDictionary(contentsOf: url)
                if let devices = dict?.object(forKey: "DeviceUUIDs") as? [String] {
                    self.uuids = devices
                    if devices.count > 0 {
                        deviceListExisted = true
                        currentDevicePresent = devices.contains(uuid)
                    }
                }
            }
            
            if (!currentDevicePresent && canAddCurrentDevice) {
                var err2:NSError? = nil
                self.uuids.append(uuid)
                let newList = NSDictionary()
                newList.setValue(self.uuids, forKey: "DeviceUUIDs")
                let baseURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
                coordinator.coordinate(writingItemAt: baseURL, options: NSFileCoordinator.WritingOptions.contentIndependentMetadataOnly, error: &err2) { url in
                    do {
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        
                    }
                }
                
                var err3:NSError? = nil
                coordinator.coordinate(writingItemAt: self.deviceListURL(), options: .forReplacing, error: &err3) { url in
                    newList.write(to: url, atomically: false)
                }
            }
            
            completion(deviceListExisted, currentDevicePresent)
        }
    }
    
    fileprivate func deviceListURL() -> URL {
        let iCloudURL:URL = FileManager.default.url(forUbiquityContainerIdentifier: nil)!
        return iCloudURL.appendingPathComponent(deviceListName)
    }
    
    fileprivate func download(_ url:URL, dispatchQueue:DispatchQueue, completion:@escaping (_ syncCompleted:Bool, _ error:NSError?) -> Void) {
        
        //check if the file is already downloaded
        var isDownloaded:AnyObject? = nil
        do {
            try (url as NSURL).getResourceValue(&isDownloaded, forKey: URLResourceKey.ubiquitousItemDownloadingStatusKey)
        } catch _ {
            
        }
        if isDownloaded as? URLUbiquitousItemDownloadingStatus == URLUbiquitousItemDownloadingStatus.current {
            completion(true, nil)
            return
        }
        
        //check if the file is currently downloading
        var isDownloading:AnyObject? = nil
        do {
            try (url as NSURL).getResourceValue(&isDownloading, forKey: URLResourceKey.ubiquitousItemIsDownloadingKey)
        } catch _ {
            
        }
        if (isDownloading as? NSNumber)?.boolValue == true {
            //do nothing - wait for next run
        } else {
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
            } catch {
                completion(false, nil)
            }
        }
        
        dispatchQueue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.download(url, dispatchQueue: dispatchQueue, completion: completion)
        }
    }
}
