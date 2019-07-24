//
//  UserLists.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class UserList: PaginatedList<GetUserListOperationFactory> {
    class func followerList(with userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("me/followers")))
    }
    
    class func followingList(with userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("me/followings")))
    }
    
    class func blockList(with userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("me/blocking")))
    }
    
    class func followerList(for user: User, userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("users/\(user.id)/followers")))
    }
    
    class func followingList(for user: User, userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("users/\(user.id)/followings")))
    }
}

class GetUserListOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    private let initialURL: URL
    
    init(session: UserSession, url: URL) {
        self.session = session
        initialURL = url
    }
    
    func makeInitialOperation() -> GetUserListOperation {
        return GetUserListOperation(session: session, url: initialURL)
    }
}


class GetUserListOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    var isBeginning: Bool {
        return true
    }
    var nextPageFetchingOperation: PaginatedFetchingOperationType? {
        return nil
    }
    var retryOperation: PaginatedFetchingOperationType? {
        return GetUserListOperation(session: session, url: url)
    }
    private(set) var items: [User] = []
    
    let session: UserSession
    private let url: URL
    
    init(session: UserSession, url: URL) {
        self.session = session
        self.url = url
    }

}
