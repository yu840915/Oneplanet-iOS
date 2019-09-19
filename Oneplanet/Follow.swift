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
    
    func increaseFollowers() {
        if counts != nil {
            counts!.followers += 1
        } else {
            refresh()
        }
    }
    
    func increaseFollowings() {
        if counts != nil {
            counts!.followings += 1
        } else {
            refresh()
        }
    }

    func decreaseFollowers() {
        if counts != nil {
            counts!.followers -= 1
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
