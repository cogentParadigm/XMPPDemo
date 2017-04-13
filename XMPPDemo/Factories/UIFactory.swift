//
//  UIFactory.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import UIKit

class UIFactory: NSObject {
    let factories:FactoryFactory
    
    init(factories:FactoryFactory) {
        self.factories = factories
        super.init()
    }
    func createWindow() -> UIWindow {
        return UIWindow(frame: UIScreen.main.bounds)
    }
    func createNavigation(root:UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)
        return nav
    }
}
