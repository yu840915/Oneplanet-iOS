//
//  AuthActions.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import FirebaseAuth
import ModelBlocks
import Alamofire

class GetAccountStateOperation: AlamofireAPIAccessOperation {
    let email: String
    var state: AccountState = .unknown
    init(email: String) {
        self.email = email
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try InputValidators.email.validate(email)
        return try Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .get, parameters: ["email": email], encoding: URLEncoding(), headers: nil)
    }
    
    override func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        try super.handleHTTPResponse(response)
    }
}

enum AccountState {
    case unknown
    case nonexist
    case verified
    case pending
}

class EmailAuthCredential {
    let inputDidChangeHandlers = MulticastCallbackNode<()->()>()
    var email: String = "" {
        didSet {
            if oldValue != email {
                inputDidChangeHandlers.invokeEach{$0()}
            }
        }
    }
    var password: String = "" {
        didSet {
            if oldValue != password {
                inputDidChangeHandlers.invokeEach{$0()}
            }
        }
    }
}
