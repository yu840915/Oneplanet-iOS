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
    class func searchList(with userSession: UserSession, query: String) -> UserList {
        let url = ServiceURLs.base.appendingPathComponent("user").addingQ(query)
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: url))
    }
    class func followerList(with userSession: UserSession) -> UserList {
        return followerList(for: userSession.profile!.user, userSession: userSession)
    }
    
    class func followingList(with userSession: UserSession) -> UserList {
        return followingList(for: userSession.profile!.user, userSession: userSession)
    }
    
    class func blockList(with userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("me/blocking")))
    }
    
    class func followerList(for user: User, userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("users/\(user.id)/followers")))
    }
    
    class func followingList(for user: User, userSession: UserSession) -> UserList {
        return UserList(operationFactory: GetUserListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("users/\(user.id)/following")))
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
        return GetUserListOperation(session: session, url: initialURL.addingFirstPageQeury())
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
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: url))
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([User].self, from: data)
    }
}
