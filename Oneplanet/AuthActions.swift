//
//  AuthActions.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks
import Alamofire

class SendEmailLinkOperation: AlamofireAPIAccessOperation {
    let email: String
    init(email: String) {
        self.email = email
    }

    override func prepareDataRequest() throws -> DataRequest {
        try InputValidators.email.validate(email)
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .post, parameters: ["email": email], encoding: JSONEncoding(), headers: nil)
    }
}

class EmailLinkLogInOperarion: AlamofireAPIAccessOperation, AuthenticationOperationType {
    let credential: EmailAuthCredential
    private(set) var token: String?
    init(credential: EmailAuthCredential) {
        self.credential = credential
    }

    override func prepareDataRequest() throws -> DataRequest {
        try credential.validate()
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .post, parameters: ["email": credential.email, "password": credential.password], encoding: JSONEncoding(), headers: nil)
    }
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
    
    func validate() throws {
        try InputValidators.email.validate(email)
        try InputValidators.password.validate(password)
    }
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch _ {
            return false
        }
    }
}

class GuestLogInOperation: AlamofireAPIAccessOperation, AuthenticationOperationType {
    private(set) var token: String?
}

protocol AuthenticationOperationType: FailableOperationType {
    var token: String? {get}
}

protocol SocialAuthenticationOperationType: AuthenticationOperationType {
    var publicProfile: PublicProfile? {get}
}

class PublicProfile {
    let nickname: String?
    let avatarURL: URL?
    init(nickname: String?, avatarURL: URL?) {
        self.nickname = nickname
        self.avatarURL = avatarURL
    }
}

