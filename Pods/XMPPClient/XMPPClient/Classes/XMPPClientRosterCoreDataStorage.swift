//
//  XMPPClientRosterCoreDataStorage.swift
//  Pods
//
//  Created by Ali Gangji on 6/30/16.
//
//

import Foundation
import XMPPFramework

open class XMPPClientRosterCoreDataStorage: XMPPRosterCoreDataStorage {
    override open func commonInit() {
        super.commonInit()
        autoRemovePreviousDatabaseFile = false
    }
    override open func managedObjectModelName() -> String! {
        return "XMPPRoster"
    }
    override open func managedObjectModelBundle() -> Bundle! {
        return Bundle(for: XMPPRosterCoreDataStorage.self)
    }
    override open func clearAllUsersAndResources(for stream: XMPPStream!) {
        //these used to override parent methods
        //prevent destruction of roster
    }
    override open func beginRosterPopulation(for stream: XMPPStream!, withVersion version: String!) {
        //prevent destruction of roster
    }
}
