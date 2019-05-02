//
//  UserSession.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import FirebaseAuth

class UserSession {
    let token: String
    var profile: MyProfile?
    var socialProfile: PublicProfile?
    
    init(token: String) {
        self.token = token
    }
    
    func addingAuthorizationToken(to headers: [String: String]) -> [String: String] {
        var result = headers
        result["Authorization"] = "Bearer \(token)"
        return result
    }
    
    func addingAuthorizationToken(to request: URLRequest) -> URLRequest {
        var result = request
        result.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return result
    }
    
    var authorizationHeader: [String: String] {
        return ["Authorization": "Bearer \(token)"]
    }
}

class MyProfile {
}

class GetMyProfileOperation: AlamofireAPIAccessOperation {
    private var profile: MyProfile?
    private var missingProfile: Bool?
    let session: UserSession
    init(session: UserSession) {
        self.session = session
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
