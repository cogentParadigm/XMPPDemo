//
//  CDALAlerts.swift
//  Pods
//
//  Created by Ali Gangji on 3/26/16.
//
//

import UIKit

open class CDALAlerts: NSObject {
    
    open func cloudPreference(_ completion:((Int)->Void)?) {
        AlertBuilder(title: "Choose Storage Option", message: "Should documents be stored in iCloud or on just this device?")
        .addAction("Local only") { _ in
            completion?(1)
        }
        .addAction("iCloud") { _ in
            completion?(2)
        }
        .show()
    }

    open func cloudDisabled(_ completion:((Int)->Void)?) {
        let title: String = "You're not using iCloud"
        var message: String = ""
        let option1: String = "Keep using iCloud"
        var option2: String = ""
        var option3: String = ""
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone) {
            message = "What would you like to do with documents currently on this phone?"
            option2 = "Keep on My iPhone"
            option3 = "Delete from My iPhone"
        } else {
            message = "What would you like to do with documents currently on this iPad?"
            option2 = "Keep on My iPad"
            option3 = "Delete from My iPad"
        }
        
        let popup = AlertBuilder(title: title, message: message)
        popup.addAction(option1) { (alert:UIAlertAction!) in
            //Keep using iCloud' selected
            completion?(1)
        }
        popup.addAction(option2) { (alert:UIAlertAction!) in
            //Keep on My iPhone selected
            completion?(2)
        }
        popup.addAction(option3) { (alert:UIAlertAction!) in
            completion?(3)
        }
        popup.show()
        
    }
    
    open func cloudSignout(_ completion:(() -> Void)?) {
        let title = "iCloud Sign-Out"
        let message = "You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents"
        let option = "OK"
        let popup = AlertBuilder(title: title, message: message, handler:completion).addAction(option) { (alert:UIAlertAction!) in
            //do nothing
        }
        popup.show()
    }
    
    open func cloudMerge(_ completion:((Int)->Void)?) {
        let title = "iCloud file exists"
        let message = "Do you want to merge the data on this device with the existing iCloud data?"
        let option1 = "Yes"
        let option2 = "No"
        let popup = AlertBuilder(title: title, message: message)
        popup.addAction(option1) { (alert:UIAlertAction!) in
            //merge
            completion?(1)
        }
        popup.addAction(option2) { (alert:UIAlertAction!) in
            //no merge
            completion?(2)
        }
        popup.show()
        
    }
}
