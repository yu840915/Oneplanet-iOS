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
    var isGuest: Bool {
        return bearerToken.isEmpty
    }
    let bearerToken: String
    let profileDidUpdate = MulticastCallbackNode<()->()>()
    private(set) var profile: MyProfile? {
        didSet {
            profileDidUpdate.invokeEach{$0()}
        }
    }
    var socialProfile: PublicProfile?
    private(set) var isActive = true
    let sessionBecomeInactiveObservers = MulticastCallbackNode<()->()>()
    
    init(token: String) {
        self.bearerToken = token
    }
    
    func updateProfile(_ profile: MyProfile) {
        profile.avatar = WebImageInfo(url: ServiceURLs.base.appendingPathComponent("me/avatar.jpg"), accessToken: bearerToken)
        self.profile = profile
    }
    
    func addingAuthorizationToken(to headers: [String: String]) -> [String: String] {
        var result = headers
        result["Authorization"] = bearerToken
        return result
    }
    
    func addingAuthorizationToken(to request: URLRequest) -> URLRequest {
        var result = request
        result.addValue(bearerToken, forHTTPHeaderField: "Authorization")
        return result
    }
    
    var authorizationHeader: [String: String] {
        return ["Authorization": bearerToken]
    }
    
    func deactivate() {
        guard isActive else { return }
        isActive = false
        sessionBecomeInactiveObservers.invokeEach{$0()}
    }
}

class MyProfile: Decodable, UserProfileDisplayable {
    let id: String
    let nickname: String
    fileprivate(set) var avatar: WebImageInfo?
    var race: Race?
    enum CodingKeys: String, CodingKey {
        case id
        case nickname = "username"
    }
    
    init(id: String, nickname: String, avatar: WebImageInfo?) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
    }
}

class GuestProfile: MyProfile {
    init() {
        super.init(id: "", nickname: "Guest", avatar: nil)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class GetMyProfileOperation: AlamofireAPIAccessOperation {
    private(set) var profile: MyProfile?
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        let req = URLRequest(url: ServiceURLs.base.appendingPathComponent("me"))
        return session.addingAuthorizationToken(to: req)
    }
    
    override func processData(with data: Data) throws {
        profile = try JSONDecoder.default.decode(MyProfile.self, from: data)
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
        Preferences.accessToken.value = session.bearerToken
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
