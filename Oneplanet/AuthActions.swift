//
//  AuthActions.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import FirebaseAuth
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
    var user: FirebaseAuth.User? {get}
}

class FacebookLoginOperation: SimpleAsynchronousOperation, SocialAuthenticationOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    var user: FirebaseAuth.User? {
        return firebaseAuthOperation?.user
    }
    let presenter: UIViewController
    private let manager: LoginManager
    private var firebaseAuthOperation: FirebaseAuthorizationOperation?
    init(presenter: UIViewController) {
        self.presenter = presenter
        manager = LoginManager(loginBehavior: .native, defaultAudience: .onlyMe)
    }
    
    override func main() {
        guard !isCancelled else { return }
        if let token = AccessToken.current {
            submitTokenToFirebase(token)
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
        submitTokenToFirebase(token)
    }
    
    private func submitTokenToFirebase(_ token: AccessToken) {
        let cred = FacebookAuthProvider.credential(withAccessToken: token.authenticationToken)
        let op = FirebaseAuthorizationOperation(credential: cred)
        op.completionBlock = {[weak self] in
            self?.didSubmitTokenToFirebase()
        }
        firebaseAuthOperation = op
        op.start()
    }
    
    private func didSubmitTokenToFirebase() {
        let op = firebaseAuthOperation!
        if let token = op.idToken {
            submitTokenToAPIServer(with: token)
        } else {
            fail(with: op.error)
        }
    }
    
    private func submitTokenToAPIServer(with token: String) {
        
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
    var user: FirebaseAuth.User? {
        return firebaseAuthOperation?.user
    }
    let presenter: UIViewController
    private var firebaseAuthOperation: FirebaseAuthorizationOperation?
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
        submitTokenToFirebase(with: session)
    }
    
    private func submitTokenToFirebase(with session: TWTRSession) {
        let cred = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
        let op = FirebaseAuthorizationOperation(credential: cred)
        op.completionBlock = {[weak self] in
            self?.didSubmitTokenToFirebase()
        }
        firebaseAuthOperation = op
        op.start()
    }
    
    private func didSubmitTokenToFirebase() {
        let op = firebaseAuthOperation!
        if let token = op.idToken {
            submitTokenToAPIServer(with: token)
        } else {
            fail(with: op.error)
        }
    }
    
    private func submitTokenToAPIServer(with token: String) {
        
    }
    
    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
    
}

class FirebaseAuthorizationOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var idToken: String?
    private(set) var user: FirebaseAuth.User?
    private let auth: Auth
    
    let credential: AuthCredential
    init(credential: AuthCredential) {
        self.credential = credential
        auth = Auth.auth()
    }
    
    override func main() {
        auth.signInAndRetrieveData(with: credential) {[weak self] (result, error) in
            self?.didSignIn(result, error: error)
        }
    }
    
    private func didSignIn(_ result: AuthDataResult?, error: Error?) {
        guard let result = result, result.user.displayName != nil else {
            fail(with: error)
            return
        }
        user = result.user
        result.user.getIDToken {[weak self] (token, error) in
            self?.didGetToken(token, error: error)
        }
    }
    
    private func didGetToken(_ token: String?, error: Error?) {
        guard let token = token else {
            fail(with: error)
            return
        }
        idToken = token
        success = true
        finish()
    }
    
    private func fail(with error: Error?) {
        signOut()
        success = false
        self.error = error
        finish()
    }
    
    private func signOut() {
        do {
            try auth.signOut()
        } catch let error {
            logger.debug("Cannot sign out of Firebase, error: \(error)")
        }
    }
}
