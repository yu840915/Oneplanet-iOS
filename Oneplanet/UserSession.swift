//
//  UserSession.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class UserSession {
    let token: String
    init(token: String) {
        self.token = token
    }
}

class RestoreUserSessionOperation: Operation {
    private(set) var session: UserSession?
}

class StoreUserSessionOperation: Operation {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
}
