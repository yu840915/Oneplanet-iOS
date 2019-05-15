//
//  UserSession.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import ModelBlocks

class UserSession {
    let token: String
    var profile: MyProfile?
    var socialProfile: PublicProfile?
    private(set) var isActive = true
    let sessionBecomeInactiveObservers = MulticastCallbackNode<()->()>()
    
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
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        sessionBecomeInactiveObservers.invokeEach{$0()}
    }
}

class MyProfile {
}

class GetMyProfileOperation: AlamofireAPIAccessOperation {
    private(set) var profile: MyProfile?
    private(set) var missingProfile: Bool? = true
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: URL(string: "https://www.google.com")!)
    }
}

class RestoreUserSessionOperation: Operation {
    private(set) var session: UserSession?
    
    override func main() {
        guard let token = Preferences.accessToken.value else {
            return
        }
        session = UserSession(token: token)
        session?.socialProfile = preparePublicProfileIfExists()
    }
    
    private func preparePublicProfileIfExists() -> PublicProfile? {
        guard let nickname = Preferences.profileNickname.value else {
            return nil
        }
        return PublicProfile(nickname: nickname, avatarURL: Preferences.profileAvatarURL.value)
    }
}

class StoreUserSessionOperation: Operation {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func main() {
        Preferences.accessToken.value = session.token
        storeNonFirebaseProfileIfNeeded()
    }
    
    private func storeNonFirebaseProfileIfNeeded() {
        guard let profile = session.socialProfile else {
            Preferences.profileNickname.value = nil
            Preferences.profileAvatarURL.value = nil
            return
        }
        Preferences.profileAvatarURL.value = profile.avatarURL
        Preferences.profileNickname.value = profile.nickname
    }
}

class LogOutOperation: Operation {
    override func main() {
        Preferences.accessToken.value = nil
        Preferences.profileAvatarURL.value = nil
        Preferences.profileNickname.value = nil
        FacebookLoginOperation.logOutIfNeeded()
    }
}
