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
    class func logOutIfNeeded() {
        if AccessToken.current != nil {
            LoginManager().logOut()
        }
    }
    
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    private(set) var profile: MyProfile?
    private(set) var publicProfile: PublicProfile?
    let presenter: UIViewController
    private let manager: LoginManager
    private var submitTokenOperation: SubmitFacebookTokenOperation?
    private var getProfileOperation: GetFacebookProfileOperation?
    private var parallelOperations = Set<Operation>()
    init(presenter: UIViewController) {
        self.presenter = presenter
        manager = LoginManager(loginBehavior: .native, defaultAudience: .onlyMe)
    }
    
    override func main() {
        guard !isCancelled else { return }
        if let token = AccessToken.current {
            submitTokenAndGetProfile(token)
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
        submitTokenAndGetProfile(token)
    }
    
    private func submitTokenAndGetProfile(_ token: AccessToken) {
        let submitToken = SubmitFacebookTokenOperation(accessToken: token)
        submitToken.completionBlock = {[weak self] in
            self?.didGetAccessToken()
        }
        submitTokenOperation = submitToken
        let getProfile = GetFacebookProfileOperation()
        getProfile.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetProfile()
            }
        }
        getProfileOperation = getProfile
        parallelOperations = Set([getProfile, submitToken])
        OperationQueue.main.addOperation {
            self.parallelOperations.forEach{$0.start()}
        }
    }
    
    private func didGetAccessToken() {
        let op = submitTokenOperation!
        parallelOperations.remove(op)
        finishIfAllDone()
    }
    
    private func didGetProfile() {
        let op = getProfileOperation!
        parallelOperations.remove(op)
        finishIfAllDone()
    }
    
    private func finishIfAllDone() {
        guard parallelOperations.isEmpty else {return}
        publicProfile = getProfileOperation?.profile
        token = submitTokenOperation?.token
        profile = submitTokenOperation?.profile
        success = submitTokenOperation?.success
        error = submitTokenOperation?.error ?? getProfileOperation?.error
        if success == false {
            manager.logOut()
        }
        finish()
    }
    
    private func fail(with error: Error?) {
        manager.logOut()
        self.error = error
        success = false
        finish()
    }
}

fileprivate class SubmitFacebookTokenOperation: LogInOperation {
    let fbAccessToken: AccessToken
    init(accessToken: AccessToken) {
        fbAccessToken = accessToken
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("login/facebook-app"), method: .post, parameters: ["access_token": fbAccessToken.authenticationToken], encoding: URLEncoding(), headers: nil)
    }
}

fileprivate class GetFacebookProfileOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var profile: PublicProfile?
    private var request: GraphRequest?
    
    override func main() {
        let req = GraphRequest(graphPath: "me")
        request = req
        req.start {[weak self] (res, result) in
            self?.handelResponse(res, result: result)
        }
    }
    
    private func handelResponse(_ response: HTTPURLResponse?, result: GraphRequestResult<GraphRequest>) {
        switch result {
        case .success(let res):
            handleResponseDate(res)
        case .failed(let error):
            fail(with: error)
        }
    }
    
    private func handleResponseDate(_ response: GraphRequest.Response) {
        guard let dict = response.dictionaryValue,
            let name = dict["name"] as? String,
            let id = dict["id"] as? String else {
            return
        }
        profile = PublicProfile(nickname: name, avatarURL: URL(string: "https://graph.facebook.com/\(id)/picture?type=large"))
        success = true
        finish()
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
    }
}
