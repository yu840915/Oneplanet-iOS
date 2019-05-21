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
    let loginType: LoginType
    private(set) var profile: MyProfile? {
        didSet {
            profileDidUpdate.invokeEach{$0()}
        }
    }
    var socialProfile: PublicProfile?
    private(set) var isActive = true
    let sessionBecomeInactiveObservers = MulticastCallbackNode<()->()>()
    private(set) var updateProfileOperation: UpdateProfileOperation?
    
    init(token: String, loginType: LoginType) {
        self.bearerToken = token
        self.loginType = loginType
    }
    
    func submitProfileChanges(with draft: ProfileDraft) {
        updateProfileOperation?.cancel()
        let op = UpdateProfileOperation(draft: draft, session: self)
        op.completionBlock = {[weak self] in
            self?.didSubmitProfileChanges()
        }
        updateProfileOperation = op
        op.start()
    }
    
    private func didSubmitProfileChanges() {
        let op = updateProfileOperation!
        updateProfileOperation = nil
        if op.success == true {
            let draft = op.draft
            profile = MyProfile(id: profile!.id, nickname: draft.nickname, gender: draft.gender, avatar: profile!.avatar)
        }
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
        updateProfileOperation?.cancel()
        updateProfileOperation = nil
        sessionBecomeInactiveObservers.invokeEach{$0()}
    }
}

enum LoginType {
    case email(String), facebook, twitter, wechat, unknown
    
    var displayName: String {
        switch self {
        case .email(let add): return add
        case .facebook: return Localized.titles.facebook
        case .twitter: return Localized.titles.twitter
        case .wechat: return Localized.titles.wechat
        case .unknown: return ""
        }
    }
    var email: String? {
        switch self {
        case .email(let add): return add
        default: return nil
        }
    }
    var socialLoginType: String? {
        switch self {
        case .facebook: return "facebook"
        case .twitter: return "twitter"
        case .wechat: return "wechat"
        default: return nil
        }
    }
    
    static func fromEmail(_ emailAdd: String) -> LoginType {
        return .email(emailAdd)
    }
    
    static func fromType(_ type: String) -> LoginType {
        switch type {
        case "facebook": return .facebook
        case "twitter": return .twitter
        case "wechat": return .wechat
        default: return .unknown
        }
    }
}

class MyProfile: Decodable, UserProfileDisplayable {
    let id: String
    let nickname: String
    fileprivate(set) var avatar: WebImageInfo?
    var race: Race?
    let gender: Gender
    enum CodingKeys: String, CodingKey {
        case id
        case nickname = "username"
    }
    
    init(id: String, nickname: String, gender: Gender = .unknown, avatar: WebImageInfo?) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        gender = .unknown
    }
}

enum Gender {
    case unknown, male, female
    var displayName: String {
        switch self {
        case .unknown: return Localized.phrases.notSpecified
        case .male: return Localized.titles.male
        case .female: return Localized.titles.female
        }
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
        session = UserSession(token: token, loginType: restoreLoginType())
        session?.socialProfile = preparePublicProfileIfExists()
    }
    
    private func restoreLoginType() -> LoginType {
        if let email = Preferences.loginEmail.value {
            return .fromEmail(email)
        }
        if let type = Preferences.socialLoginType.value {
            return .fromType(type)
        }
        return .unknown
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
        Preferences.loginEmail.value = session.loginType.email
        Preferences.socialLoginType.value = session.loginType.socialLoginType
        storePublicProfileIfNeeded()
    }
    
    private func storePublicProfileIfNeeded() {
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
