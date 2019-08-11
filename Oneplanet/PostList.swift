//
//  PostList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/31.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class Post {
    let id: String
    let author: User = User(id: "123", username: "Mike 123", nickname: "Mike", character: AlienOptions.shared.alien(for: .one, color: .blue))
    init(id: String) {
        self.id = id
    }
}

class PostList: PaginatedList<GetPostListOperationFactory> {
    class func postList(with userSession: UserSession) -> PostList {
        return PostList(operationFactory: GetPostListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("posts")))
    }

    class func myPostList(with userSession: UserSession) -> PostList {
        return PostList(operationFactory: GetPostListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("me/posts")))
    }
    
    class func userPostList(with userSession: UserSession, for user: User) -> PostList {
        return PostList(operationFactory: GetPostListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("users/\(user.id)/posts")))
    }
    
    class func promotedPostList(with userSession: UserSession) -> PostList {
        return PostList(operationFactory: GetPostListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("posts?promoted=1")))
    }
}

class GetPostListOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    private let initialURL: URL
    
    init(session: UserSession, url: URL) {
        self.session = session
        initialURL = url
    }
    
    func makeInitialOperation() -> GetPostListOperation {
        return GetPostListOperation(session: session, url: initialURL)
    }
}

class GetPostListOperation:  AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    var isBeginning: Bool {
        return true
    }
    var nextPageFetchingOperation: PaginatedFetchingOperationType? {
        return nil
    }
    var retryOperation: PaginatedFetchingOperationType? {
        return GetPostListOperation(session: session, url: url)
    }
    private(set) var items: [Post] = []
    
    let session: UserSession
    private let url: URL
    
    init(session: UserSession, url: URL) {
        self.session = session
        self.url = url
    }
}
