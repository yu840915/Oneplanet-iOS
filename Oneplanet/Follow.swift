//
//  Follow.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import ModelBlocks

class SocialRelationshipRepository {
    private(set) weak var userSession: UserSession!
    private var relationships: [String: SocialRelationship] = [:]
    let relationUpdateObservers = MulticastCallbackNode<()->()>()
    private var updateHandles: [Any] = []
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func relationship(with user: User) -> SocialRelationship? {
        if user.id == userSession.profile?.id { return nil }
        if let rel = relationships[user.id] {
            rel.initializeIfNeeded()
            return rel
        }
        let value = SocialRelationship(userID: user.id, userSession: userSession)
        relationships[user.id] = value
        updateHandles.append(value.updateObservers.add {[weak self] in
            self?.relationUpdateObservers.invokeEach{$0()}
        })
        value.initializeIfNeeded()
        return value
    }
}

class SocialRelationship {
    let userID: String
    let updateObservers = MulticastCallbackNode<()->()>()
    private(set) var states: SocialRelationshipStates? {
        didSet {
            updateObservers.invokeEach{$0()}
        }
    }
    private(set) weak var userSession: UserSession!
    private var getStateOperation: GetFollowStateOperation?
    private var followOperation: FollowUserOperation?
    
    init(userID: String, userSession: UserSession) {
        self.userID = userID
        self.userSession = userSession
    }
    
    func initializeIfNeeded() {
        guard states == nil && getStateOperation == nil else {
            return
        }
        let op = GetFollowStateOperation(userID: userID, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetFollowStates()
            }
        }
        getStateOperation = op
        op.start()
    }
    
    private func didGetFollowStates() {
        let op = getStateOperation!
        getStateOperation = nil
        if let isFollowing = op.isFollowing {
            var states = self.states ?? SocialRelationshipStates(isFollowing: false, isBlocking: false)
            states.isFollowing = isFollowing
            self.states = states
        }
    }
    
    func follow() {
        changeFollowState(true)
    }
    
    func unfollow() {
        changeFollowState(false)
    }
    
    private func changeFollowState(_ willFollow: Bool) {
        if let states = self.states, states.isFollowing == willFollow {
            return
        }
        if followOperation?.willFollow == willFollow {
            return
        }
        followOperation?.cancel()
        let op = FollowUserOperation(userID: userID, session: userSession, willFollow: willFollow)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didChangeFollowState()
            }
        }
        op.start()
        followOperation = op
    }
    
    private func didChangeFollowState() {
        let op = followOperation!
        followOperation = nil
        if op.success == true {
            if var states = self.states {
                states.isFollowing = op.willFollow
                self.states = states
            } else {
                initializeIfNeeded()
            }
            if op.willFollow {
                userSession.followCounts.increaseFollowings()
            } else {
                userSession.followCounts.decreaseFollowings()
            }
        }
    }
}

struct SocialRelationshipStates {
    var isFollowing: Bool
    var isBlocking: Bool
}

fileprivate class GetFollowStateOperation: AlamofireAPIAccessOperation {
    let userID: String
    let session: UserSession
    private(set) var isFollowing: Bool? = false
    init(userID: String, session: UserSession) {
        self.userID = userID
        self.session = session
    }

    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("users/\(userID)/follow"), method: .head))
    }
}

fileprivate class FollowUserOperation: AlamofireAPIAccessOperation {
    let userID: String
    let session: UserSession
    let willFollow: Bool

    init(userID: String, session: UserSession, willFollow: Bool) {
        self.userID = userID
        self.session = session
        self.willFollow = willFollow
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("users/\(userID)/follow"), method: willFollow ? .put : .delete, parameters: ["id": userID], encoding: JSONEncoding(), headers: session.authorizationHeader)
    }
}

class MyFollowCounts {
    var updateHandler: (()->())?
    private(set) weak var userSession: UserSession!
    private var getCountsOperation: GetUserFollowCountsOperation?
    private var lastUpdateDate: Date?
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    private(set) var counts: FollowCounts? {
        didSet {
            updateHandler?()
        }
    }
    
    func increaseFollowings() {
        if counts != nil {
            counts!.followings += 1
        } else {
            refresh()
        }
    }

    func decreaseFollowings() {
        if counts != nil {
            counts!.followings -= 1
        } else {
            refresh()
        }
    }

    func refreshIfNeeded() {
        if let date = lastUpdateDate,
            date.timeIntervalSinceNow.magnitude < 30 * .minute {
            return
        }
        guard counts == nil else { return }
        refresh()
    }
    
    func refresh() {
        guard getCountsOperation == nil else { return }
        guard let session = userSession,
            let user = userSession.profile?.user else {
                return
        }
        let op = GetUserFollowCountsOperation(user: user, session: session)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {[weak self] in
                self?.didRefresh()
            }
        }
        getCountsOperation = op
        op.start()
    }
    
    private func didRefresh() {
        let op = getCountsOperation!
        getCountsOperation = nil
        if let counts = op.counts {
            self.counts = counts
            lastUpdateDate = Date()
        }
    }
}

struct FollowCounts {
    var followers: Int
    var followings: Int
}

class GetUserFollowCountsOperation: SimpleAsynchronousOperation {
    let user: User
    let session: UserSession
    private(set) var counts: FollowCounts?
    private var getFollowerCount: GetFollowCountsOperation?
    private var getFollowingCount: GetFollowCountsOperation?
    private var getCountsOperation: ConcurrentTaskOperation<GetFollowCountsOperation>?
    init(user: User, session: UserSession) {
        self.user = user
        self.session = session
    }
    
    override func main() {
        let follower = GetFollowCountsOperation.forFollowers(of: user, session: session)
        getFollowerCount = follower
        let following = GetFollowCountsOperation.forFollowerings(of: user, session: session)
        getFollowingCount = following
        let op = ConcurrentTaskOperation<GetFollowCountsOperation>(operations: [follower, following])
        op.completionBlock = {[weak self] in
            self?.handleCounts()
        }
        getCountsOperation = op
        op.start()
    }
    
    private func handleCounts() {
        if let followers = getFollowerCount?.count,
            let followings = getFollowingCount?.count {
            counts = FollowCounts(followers: followers, followings: followings)
        }
        finish()
    }
}

class GetFollowCountsOperation: AlamofireAPIAccessOperation {
    class func forFollowers(of user: User, session: UserSession) -> GetFollowCountsOperation {
        return GetFollowCountsOperation(path: "users/\(user.id)/followers", session: session)
    }
    class func forFollowerings(of user: User, session: UserSession) -> GetFollowCountsOperation {
        return GetFollowCountsOperation(path: "users/\(user.id)/following", session: session)
    }

    let url: URL
    let session: UserSession
    private(set) var count: Int?
    
    init(path: String, session: UserSession) {
        url = ServiceURLs.base.appendingPathComponent(path)
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: try URLRequest(url: url, method: .head))
    }
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        if let count = header["X-Total-Count"] as? String {
            self.count = SharedNumberFormatters.integer.number(from: count)?.intValue
        }
    }
}
