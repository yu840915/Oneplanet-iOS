//
//  PostList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/31.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class Post: Decodable {
    let id: String
    let authorID: String
    let caption: String
    let imageURLs: [URL]
    let createdAt: Date
    let type: String?
    let liked: Bool
    var sticky: Bool {
        return stickerInfo != nil
    }
    let stickerInfo: StikerInfo?
    var images: [WebImageInfo] {
        return imageURLs.map{WebImageInfo(url: $0)}
    }
    let score: Int?
    
    init(post: Post, caption: String) {
        id = post.id
        authorID = post.authorID
        self.caption = caption
        imageURLs = post.imageURLs
        createdAt = post.createdAt
        type = post.type
        score = post.score
        liked = post.liked
        stickerInfo = post.stickerInfo
    }
    
    enum CodingKeys: String, CodingKey {
        case id, caption
        case authorID = "user"
        case imageURLs = "images"
        case createdAt = "created_at"
        case type
        case score
        case liked = "favorited"
        case stickerInfo = "sticky"
    }
}

class StikerInfo: Decodable {
}

enum PostType: String {
    case valued = "score"
    case free
}

class PostList: PaginatedList<GetPostListOperationFactory> {
    class func postList(with userSession: UserSession) -> PostList {
        return PostList(operationFactory: GetPostListOperationFactory(session: userSession, url: ServiceURLs.base.appendingPathComponent("posts").addingFirstPageQeury()))
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
    var isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetPostListOperation(session: session, url: url)
    }
    private(set) var items: [Post] = []
    
    let session: UserSession
    private let url: URL
    
    init(session: UserSession, url: URL, isBeginning: Bool = true) {
        self.session = session
        self.url = url
        self.isBeginning = isBeginning
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: url))
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([Post].self, from: data)
    }
    
    override func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        try super.handleHTTPResponse(response)
        prepareNextPage(from: response)
    }
    
    private func prepareNextPage(from response: HTTPURLResponse) {
        let finder = WebLinkingKeyMap(links: response.links)
        guard let url = finder.findLink(in: response, for: PageRelation.next) else  {
            return
        }
        nextPageFetchingOperation = GetPostListOperation(session: session, url: url, isBeginning: false)
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}

class DeduplicationHelper {
    private var ids = Set<String>()
    func addIfAllowed(_ id: String) -> Bool {
        if ids.contains(id) {
            return false
        }
        ids.insert(id)
        return true
    }
}

class ChangePinOperation: AlamofireAPIAccessOperation {
    let post: Post
    let session: UserSession
    let isPinning: Bool
    
    init(post: Post, session: UserSession, isPinning: Bool) {
        self.post = post
        self.session = session
        self.isPinning = isPinning
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        guard session.isAdmin else {
            throw GenericAppError("Only admin can pin")
        }
        return session.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("posts/\(post.id)/sticky"), method: isPinning ? .put : .delete))
    }
}

class LikePostOperation: AlamofireAPIAccessOperation {
    let post: Post
    let session: UserSession
    
    init(post: Post, session: UserSession) {
        self.post = post
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        guard session.isAdmin else {
            throw GenericAppError("Only admin can pin")
        }
        return session.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("posts/\(post.id)/favorite"), method: .post))
    }
}
