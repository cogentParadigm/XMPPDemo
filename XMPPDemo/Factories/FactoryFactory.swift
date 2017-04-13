//
//  FactoryFactory.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import Foundation

class FactoryFactory: NSObject {
    let host:String
    
    lazy var ui:UIFactory = {
        return UIFactory(factories:self)
    }()
    lazy var controllers:ControllerFactory = {
        return ControllerFactory(factories:self)
    }()
    lazy var io:IOFactory = {
        return IOFactory(factories:self)
    }()
    lazy var cd:DBFactory = {
        return DBFactory()
    }()
    
    init(host:String) {
        self.host = host
        super.init()
    }
}
