//
//  TwitterLogIn.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/6.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire
import TwitterKit

struct TwitterCredentials {
    static let key = "pGvVuFgTun2H2yPeMICtD6j0E"
    static let secret = "iQQTaLzRwLmKYvKUz46uES0JBObeV3kjI4JBklDp4U5xX8pvdw"
}

class TwitterLogInOperation: SimpleAsynchronousOperation, SocialAuthenticationOperationType {
    class func logOutIfNeeded() {
        guard TWTRTwitter.sharedInstance().sessionStore.hasLoggedInUsers() else {
            return
        }
        TWTRTwitter.sharedInstance().sessionStore.existingUserSessions().forEach {
            if let session = $0 as? TWTRAuthSession {
                TWTRTwitter.sharedInstance().sessionStore.logOutUserID(session.userID)
            }
        }
    }
    
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    private(set) var profile: MyProfile?
    private(set) var publicProfile: PublicProfile?
    let presenter: UIViewController
    private var submitTokenOperation: SubmitTwitterTokenOperation?
    private var getProfileOperation: GetTwitterProfileOperation?
    private var parallelOperations = Set<Operation>()
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
        submitTokenAndGetProfile(with: session)
    }
    
    private func submitTokenAndGetProfile(with session: TWTRSession) {
        let submitToken = SubmitTwitterTokenOperation(session: session)
        submitToken.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetAccessToken()
            }
        }
        submitTokenOperation = submitToken
        let getProfile = GetTwitterProfileOperation(session: session)
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
            TwitterLogInOperation.logOutIfNeeded()
        }
        finish()
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
        TwitterLogInOperation.logOutIfNeeded()
        finish()
    }
}

fileprivate class SubmitTwitterTokenOperation: LogInOperation {
    let session: TWTRSession
    init(session: TWTRSession) {
        self.session = session
    }

    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("login/twitter-app"), method: .post, parameters: ["oauth_token": session.authToken, "oauth_token_secret": session.authTokenSecret], encoding: URLEncoding(), headers: nil)
    }
}

fileprivate class GetTwitterProfileOperation: SimpleAsynchronousOperation, FailableOperationType {
    let session: TWTRSession
    private let client: TWTRAPIClient
    
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var profile: PublicProfile?

    init(session: TWTRSession) {
        self.session = session
        client = TWTRAPIClient(userID: session.userID)
    }
    
    override func main() {
        client.loadUser(withID: session.userID) {[weak self] (user, error) in
            self?.didLoadUser(user, error: error)
        }
    }
    
    private func didLoadUser(_ user: TWTRUser?, error: Error?) {
        self.error = error
        guard let user = user else {
            success = false
            finish()
            return
        }
        profile = PublicProfile(nickname: user.name, avatarURL: URL(string: user.profileImageLargeURL))
        success = true
        finish()
    }
}
