//
//  UserSession.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import ModelBlocks

class UserSession {
    var isGuest: Bool {
        return bearerToken.isEmpty
    }
    var isBanned: Bool {
        return false
    }
    var isAdmin: Bool {
        return false
    }
    let bearerToken: String
    let profileDidUpdate = MulticastCallbackNode<()->()>()
    let postListDidUpdate = MulticastCallbackNode<(Post?)->()>()
    let loginType: LoginType
    let userFetcherRepo = UserFetcherRepository()
    private(set) var socialRelationshipRepo: SocialRelationshipRepository!
    private(set) var followCounts: MyFollowCounts!
    private(set) var wallet: Wallet!
    private(set) var bidProcessManager: ProductBidProcessManager!
    private(set) var profile: MyProfile? {
        didSet {
            profileDidUpdate.invokeEach{$0()}
        }
    }
    private(set) var lotList: MyLotList!
    var socialProfile: PublicProfile?
    private(set) var bidPhaseIndicator: BidPhaseIndicator!
    private(set) var isActive = true
    let sessionBecomeInactiveObservers = MulticastCallbackNode<()->()>()
    private(set) var updateProfileOperation: UpdateProfileOperation?
    private var submitProfileCompletion: ((Bool, Error?)->())?
    let hiddenPosts = HiddenPosts()
    
    init(token: String, loginType: LoginType) {
        self.bearerToken = token
        self.loginType = loginType
        lotList = MyLotList(session: self)
        bidProcessManager = ProductBidProcessManager(userSession: self)
        if !isGuest {
            lotList.reload()
            wallet = Wallet(userSession: self)
            followCounts = MyFollowCounts(userSession: self)
            socialRelationshipRepo = SocialRelationshipRepository(userSession: self)
            followCounts.updateHandler = {[weak self] in
                self?.profileDidUpdate.invokeEach{$0()}
            }
        }
    }
    
    func updateBidPhaseIndicator(with timeframe: SessionTimeframe) {
        if let indicator = bidPhaseIndicator {
            indicator.update(with: timeframe)
        } else {
            bidPhaseIndicator = BidPhaseIndicator(sessionTimeframe: timeframe, bidProcessManager: bidProcessManager)
        }
    }
    
    func submitProfileChanges(with draft: ProfileDraft, completion: ((Bool, Error?)->())? = nil) {
        updateProfileOperation?.cancel()
        let op = UpdateProfileOperation(draft: draft, session: self)
        op.completionBlock = {[weak self] in
            self?.didSubmitProfileChanges()
        }
        updateProfileOperation = op
        submitProfileCompletion = completion
        op.start()
    }
    
    private func didSubmitProfileChanges() {
        let op = updateProfileOperation!
        updateProfileOperation = nil
        if op.success == true {
            let draft = op.draft
            var avatar: WebImageInfo?
            if let url = draft.avatar?.progress.imageLocation?.url {
                avatar = WebImageInfo(url: url)
            }
            let profile = MyProfile(id: self.profile!.id, username: draft.username, nickname: draft.nickname, gender: draft.gender, avatar: avatar)
            profile.alien = draft.alien
            self.profile = profile
        }
        submitProfileCompletion?(op.success ?? false, op.error)
        submitProfileCompletion = nil
    }
    
    func updateProfile(_ profile: MyProfile) {
        self.profile = profile
        if !isGuest {
            followCounts.refreshIfNeeded()
        }
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
    
    func broadcastPostPublish(_ post: Post?) {
        postListDidUpdate.invokeEach{$0(post)}
    }
    
    func notifyPostDidDelete(_ post: Post?) {
        postListDidUpdate.invokeEach{$0(post)}
    }
    
    func notifyPostListUpdate() {
        postListDidUpdate.invokeEach{$0(nil)}
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
    var user: User {
        return User(id: id, username: username, nickname: nickname, character: alien)
    }
    let id: String
    let nickname: String
    let username: String
    let avatar: WebImageInfo?
    var alien: Alien?
    let gender: Gender
    var isEmpty: Bool {
        return username.isEmpty
    }
    enum CodingKeys: String, CodingKey {
        case id
        case nickname = "display_name"
        case username
        case gender
        case alien
        case avatar
    }
    
    init(id: String, username: String, nickname: String, gender: Gender, avatar: WebImageInfo?) {
        self.id = id
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
        self.username = username
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        gender = Gender.from(try container.decodeIfPresent(String.self, forKey: .gender))
        alien = try container.decodeIfPresent(Alien.self, forKey: .alien)
        if let url = try container.decodeIfPresent(URL.self, forKey: .avatar) {
            avatar = WebImageInfo(url: url)
        } else {
            avatar = nil
        }
    }
    
    func updating(with draft: ProfileDraft) -> MyProfile {
        let profile = MyProfile(id: id,
                                username: draft.username,
                                nickname: draft.nickname,
                                gender: draft.gender,
                                avatar: avatar)
        profile.alien = draft.alien
        return profile
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
    static var options: [Gender] = [.unknown, .male, .female]
    static func from(_ rawValue: String?) -> Gender {
        guard let val = rawValue else {return .unknown}
        switch val.lowercased() {
        case "m": return .male
        case "f": return .female
        default: return .unknown
        }
    }
    
    func toString() -> String? {
        switch self {
        case .male: return "M"
        case .female: return "F"
        default: return nil
        }
    }
}

class GuestProfile: MyProfile {
    init() {
        super.init(id: "", username: "guest", nickname: "Guest", gender: .unknown, avatar: nil)
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
        let req = URLRequest(url: ServiceURLs.devBase.appendingPathComponent("me"))
        return session.addingAuthorizationToken(to: req)
    }
    
    override func processData(with data: Data) throws {
        profile = try JSONDecoder.default.decode(MyProfile.self, from: data)
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
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

class FeatureAccessCheckOperation: Operation {
    let userSession: UserSession
    private(set) var isAccessible = false
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    override func main() {
        isAccessible = !userSession.isGuest
        if !userSession.isGuest {
            return
        }
        guard let presenter = FrontViewControllerFinder.findFront() else {
            return
        }
        let alert = UIAlertController(title: Localized.phrases.joinPrompt, message: Localized.messages.joinPrompt, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: {[userSession] (_) in
            userSession.deactivate()
        }))
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        presenter.present(alert, animated: true, completion: nil)
    }
}

class HiddenPosts {
    let didUpdateHandlers = MulticastCallbackNode<()->()>()
    
    private(set) var postIDs = Set<String>() {
        didSet {
            if oldValue != postIDs {
                didUpdateHandlers.invokeEach{$0()}
            }
        }
    }
    
    func hide(_ post: Post) {
        postIDs.insert(post.id)
    }
    
    func unhide(_ post: Post) {
        postIDs.remove(post.id)
    }
    
    func isHidden(_ post: Post) -> Bool {
        return postIDs.contains(post.id)
    }
}
