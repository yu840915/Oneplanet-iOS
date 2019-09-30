//
//  NoticeList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class NoticeList: PaginatedList<GetNoticePageOperationFactory> {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
        super.init(operationFactory: GetNoticePageOperationFactory(session: session))
    }
}

class GetNoticePageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    
    var items: [Notice] = []
    let isBeginning: Bool
    
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetNoticePageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    let session: UserSession
    private let url: URL
    
    init(session: UserSession, url: URL, isBeginning: Bool) {
        self.session = session
        self.isBeginning = isBeginning
        self.url = url
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        let req = URLRequest(url: url)
        return session.addingAuthorizationToken(to: req)
    }

    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([Notice].self, from: data).compactMap{$0.concreteNotice}
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
        nextPageFetchingOperation = GetNoticePageOperation(session: session, url: url, isBeginning: false)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}

class GetNoticePageOperationFactory: PaginatedFetchingOperationFactoryType {
    
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetNoticePageOperation {
        return GetNoticePageOperation(session: session, url: ServiceURLs.base.appendingPathComponent("notices").addingFirstPageQeury(), isBeginning: true)
    }
}

class Notice: Decodable {
    let typeString: String
    var type: NoticeType {
        return NoticeType(rawValue: typeString) ?? .unknwon
    }
    let isRead: Bool
    let date: Date
    let meta: NoticeMeta
    
    enum CodingKeys: String, CodingKey {
        case isRead = "is_read"
        case typeString = "cls"
        case date = "created_at"
        case meta
    }
    
    init(typeString: String, date: Date, isRead: Bool, meta: NoticeMeta) {
        self.typeString = typeString
        self.date = date
        self.isRead = isRead
        self.meta = meta
    }
    
    var concreteNotice: Notice? {
        switch type {
        case .bonus: return BonusNotice(with: self)
        case .followNotice: return FollowNotice(with: self)
        case .reported: return PostReportedNotice(with: self) ?? ProfileReportedNotice(with: self)
        case .banned: return nil
        case .unknwon: return nil
        }
    }
}

class BonusNotice: Notice {
    let eventID: String
    
    init?(with notice: Notice) {
        guard notice.type == .bonus, let id = notice.meta.bonusEventID else {
            return nil
        }
        eventID = id
        super.init(typeString: notice.typeString, date: notice.date, isRead: notice.isRead, meta: notice.meta)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class FollowNotice: Notice {
    let followerID: String

    init?(with notice: Notice) {
        guard notice.type == .followNotice, let id = notice.meta.followerID else {
            return nil
        }
        followerID = id
        super.init(typeString: notice.typeString, date: notice.date, isRead: notice.isRead, meta: notice.meta)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class PostReportedNotice: Notice {
    let postID: String
    let reason: String

    init?(with notice: Notice) {
        guard notice.type == .reported,
            let id = notice.meta.postID,
            let key = notice.meta.reason else {
            return nil
        }
        postID = id
        reason = key
        super.init(typeString: notice.typeString, date: notice.date, isRead: notice.isRead, meta: notice.meta)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class ProfileReportedNotice: Notice {
    let reason: String

    init?(with notice: Notice) {
        guard notice.type == .reported,
            let key = notice.meta.reason else {
                return nil
        }
        reason = key
        super.init(typeString: notice.typeString, date: notice.date, isRead: notice.isRead, meta: notice.meta)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class NoticeMeta: Decodable {
    let bonusEventID: String?
    let followerID: String?
    let reason: String?
    let postID: String?
    
    enum CodingKeys: String, CodingKey {
        case bonusEventID = "event_id"
        case followerID = "follower"
        case postID = "post_id"
        case reason
    }
}

enum NoticeType: String, Decodable {
    case bonus = "bonus.event"
    case followNotice = "follow"
    case reported = "report"
    case banned = "banned"
    case unknwon
}

class NoticeUnreadCount {
    let userSession: UserSession
    let updateHandlers = MulticastCallbackNode<()->()>()
    private var refreshOperation: GetNoticeUnreadCountOperation?
    private(set) var count: Int? {
        didSet {
            updateHandlers.invokeEach{$0()}
        }
    }
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    deinit {
        refreshOperation?.cancel()
    }
    
    func refresh() {
        guard refreshOperation == nil else { return }
        let op  = GetNoticeUnreadCountOperation(session: userSession)
        op.completionBlock = {[weak self] in
            self?.didRefresh()
        }
        refreshOperation = op
        op.start()
    }
    
    private func didRefresh() {
        let op = refreshOperation!
        refreshOperation = nil
        if let count = op.count {
            self.count = count
        }
    }
}

class GetNoticeUnreadCountOperation: AlamofireAPIAccessOperation {
    let session: UserSession
    private(set) var count: Int?
    init(session: UserSession) {
        self.session = session
    }

    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("notices"), method: .head))
    }
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        if let count = header["X-Total-Count"] as? String {
            self.count = SharedNumberFormatters.integer.number(from: count)?.intValue
        }
    }
}
