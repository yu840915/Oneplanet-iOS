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
import FacebookCore
import FacebookLogin
import TwitterKit

class GetAccountStateOperation: AlamofireAPIAccessOperation {
    let email: String
    var state: AccountState = .unknown
    init(email: String) {
        self.email = email
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try InputValidators.email.validate(email)
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .get, parameters: ["email": email], encoding: URLEncoding(), headers: nil)
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

class SendEmailVerificationOperation: AlamofireAPIAccessOperation {
    let email: String
    init(email: String) {
        self.email = email
    }

    override func prepareDataRequest() throws -> DataRequest {
        try InputValidators.email.validate(email)
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .post, parameters: ["email": email], encoding: JSONEncoding(), headers: nil)
    }
}

class EmailSignUpOperarion: AlamofireAPIAccessOperation, AuthenticationOperationType {
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

class EmailLogInOperarion: AlamofireAPIAccessOperation, AuthenticationOperationType {
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

class SendResetPasswordLinkOperation: AlamofireAPIAccessOperation {
    let email: String
    init(email: String) {
        self.email = email
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try InputValidators.email.validate(email)
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("auth"), method: .post, parameters: ["email": email], encoding: JSONEncoding(), headers: nil)
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

class FacebookLoginOperation: SimpleAsynchronousOperation, SocialAuthenticationOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    private(set) var publicProfile: PublicProfile?
    let presenter: UIViewController
    private let manager: LoginManager
    private var submitTokenOperation: SubmitFacebookTokenOperation?
    init(presenter: UIViewController) {
        self.presenter = presenter
        manager = LoginManager(loginBehavior: .native, defaultAudience: .onlyMe)
    }
    
    override func main() {
        guard !isCancelled else { return }
        if let token = AccessToken.current {
            submitToken(token)
        } else {
            manager.logIn(readPermissions: [.publicProfile], viewController: presenter) {[weak self] (result) in
                self?.didLogIn(with: result)
            }
        }
    }
    
    private func didLogIn(with result: LoginResult) {
        switch result {
        case .failed(let error):
            fail(with: error)
        case .cancelled:
            success = false
            finish()
        case .success(let grantedPermissions, let declinedPermissions, let token):
            handleSucessLogin(with: token, granted: grantedPermissions, declined: declinedPermissions)
        }
    }
    
    private func handleSucessLogin(with token: AccessToken, granted: Set<Permission>, declined: Set<Permission>) {
        guard granted.contains(Permission(name: "public_profile")) else {
            fail(with: GenericAppError("You need to grant public profile access to use Facebook login"))
            return
        }
        submitToken(token)
    }
    
    private func submitToken(_ token: AccessToken) {
        let op = SubmitFacebookTokenOperation(accessToken: token)
        op.completionBlock = {[weak self] in
            self?.didGetAccessToken()
        }
        submitTokenOperation = op
        op.start()
    }
    
    private func didGetAccessToken() {
        let op = submitTokenOperation!
        if let token = op.token {
            self.token = token
        } else {
            fail(with: op.error)
        }
    }
    
    private func fail(with error: Error?) {
        manager.logOut()
        self.error = error
        success = false
        finish()
    }
}

class TwitterLogInOperation: SimpleAsynchronousOperation, SocialAuthenticationOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    private(set) var publicProfile: PublicProfile?
    let presenter: UIViewController
    private var submitTokenOperation: SubmitTwitterTokenOperation?
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    override func main() {
        guard !isCancelled else { return }
        TWTRTwitter.sharedInstance().logIn(with: presenter) {[weak self] (session, error) in
            self?.didLogIn(session, error: error)
        }
    }
    
    private func didLogIn(_ session: TWTRSession?, error: Error?) {
        guard let session = session else {
            fail(with: error)
            return
        }
        submitToken(with: session)
    }
    
    private func submitToken(with session: TWTRSession) {
        let op = SubmitTwitterTokenOperation(session: session)
        op.completionBlock = {[weak self] in
            self?.didGetAccessToken()
        }
        submitTokenOperation = op
        op.start()
    }
    
    private func didGetAccessToken() {
        let op = submitTokenOperation!
        if let token = op.token {
            self.token = token
        } else {
            fail(with: op.error)
        }
    }
    
    private func fail(with error: Error?) {
        if let err = (error as NSError?),
            let code = TWTRLogInErrorCode(rawValue: err.code) {
            switch code {
            case .logInErrorCodeCancelled, .logInErrorCodeDenied: break
            default: self.error = err
            }
        } else {
            self.error = error
        }
        success = false
        finish()
    }
}

class SubmitFacebookTokenOperation: AlamofireAPIAccessOperation, AuthenticationOperationType {
    let fbAccessToken: AccessToken
    private(set) var token: String?
    init(accessToken: AccessToken) {
        fbAccessToken = accessToken
    }
}

class SubmitTwitterTokenOperation: AlamofireAPIAccessOperation, AuthenticationOperationType {
    let session: TWTRSession
    private(set) var token: String?
    init(session: TWTRSession) {
        self.session = session
    }
}


class PublicProfile {
    let nickname: String?
    let avatarURL: URL?
    init(nickname: String?, avatarURL: URL?) {
        self.nickname = nickname
        self.avatarURL = avatarURL
    }
}
