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
    
    override func prepareURLRequest() throws -> URLRequest {
        try InputValidators.email.validate(email)
        var comp = URLComponents(url: ServiceURLs.devBase.appendingPathComponent("verify/email"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "email", value: email)]
        var req = try URLRequest(url: try comp.asURL(), method: .post)
        req.addValue(Localized.languageCode, forHTTPHeaderField: Localized.acceptLanguageKey)
        return req
    }
}

class LogInOperation: AlamofireAPIAccessOperation, AuthenticationOperationType {
    private(set) var token: String?
    private(set) var profile: MyProfile?
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        guard let bearer = header["Authorization"] as? String else {
            throw GenericAppError("Missing bearer token from log in")
        }
        token = bearer
    }
    
    override func processData(with data: Data) throws {
        profile = try JSONDecoder.default.decode(MyProfile.self, from: data)
    }
}

class EmailLinkLogInOperarion: LogInOperation {
    let credential: EmailAuthCredential
    init(credential: EmailAuthCredential) {
        self.credential = credential
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        try credential.validate()
        var comp = URLComponents(url: ServiceURLs.devBase.appendingPathComponent("login/email"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "email", value: credential.email),
                           URLQueryItem(name: "code", value: credential.code!)]
        return try URLRequest(url: try comp.asURL(), method: .post)
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
    var magicLink: URL? = nil {
        didSet {
            if oldValue != magicLink {
                inputDidChangeHandlers.invokeEach{$0()}
            }
        }
    }
    var code: String? {
        guard let link = magicLink else { return nil }
        let comp = URLComponents(url: link, resolvingAgainstBaseURL: false)
        return comp?.queryItems?.first{$0.name == "code"}?.value
    }
    
    func validate() throws {
        try InputValidators.email.validate(email)
        if code == nil {
            throw InputError(localizedDescription: "Code cannot be nil")
        }
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

class GuestLogInOperation: Operation, AuthenticationOperationType {
    let success: Bool? = true
    let error: Error? = nil
    let token: String? = ""
    let profile: MyProfile? = GuestProfile()
}

protocol AuthenticationOperationType: FailableOperationType {
    var token: String? {get}
    var profile: MyProfile? {get}
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

