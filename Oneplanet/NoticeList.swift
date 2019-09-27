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
        let infos = try JSONDecoder.default.decode([NoticeInfo].self, from: data)
        items = infos.compactMap{Notice($0)}
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

class NoticeInfo: Decodable {
    
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

class Notice {
    let isRead: Bool
    let type: NoticeType
    let date: Date = Date()
    
    init?(_ info: NoticeInfo) {
        return nil
    }
    
    init(type: NoticeType, isRead: Bool) {
        self.type = type
        self.isRead = isRead
    }
}

enum NoticeType {
    case likeFromOfficialAccount
    case giftFromOfficialAccount
    case followNotice
    case postReported
    case profileReported
}

