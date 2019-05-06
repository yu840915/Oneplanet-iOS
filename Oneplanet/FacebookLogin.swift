//
//  FacebookLogin.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/6.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire
import FacebookCore
import FacebookLogin

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

class SubmitFacebookTokenOperation: AlamofireAPIAccessOperation, AuthenticationOperationType {
    let fbAccessToken: AccessToken
    private(set) var token: String?
    init(accessToken: AccessToken) {
        fbAccessToken = accessToken
    }
}

