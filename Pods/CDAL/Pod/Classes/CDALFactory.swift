//
//  CDALFactory.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

open class CDALFactory: NSObject {
    open func create(_ modelName:String, localStoreName:String, cloudStoreName:String) -> CDALManager {
        let local = CDALLocalBackend(name: localStoreName)
        let cloud = CDALCloudBackend(name: cloudStoreName)
        let CDAL = CDALManager(modelName:modelName)
        CDAL.setLocalBackend(local)
        CDAL.setCloudBackend(cloud)
        return CDAL
    }
}
