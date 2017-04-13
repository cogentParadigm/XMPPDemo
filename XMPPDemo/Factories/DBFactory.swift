//
//  DBFactory.swift
//  XMPPDemo
//
//  Created by Ali Gangji on 4/12/17.
//  Copyright © 2017 Neon Rain Interactive. All rights reserved.
//

import CDAL

class DBFactory: NSObject {
    lazy var manager:CDALManager = {
        return CDALFactory().create("XMPPDemo", localStoreName: "XMPP", cloudStoreName: "XMPP_ICLOUD")
    }()
    lazy var db:CDALDatabase = {
        return CDALDatabase(context:self.manager.mainContext())
    }()
}
