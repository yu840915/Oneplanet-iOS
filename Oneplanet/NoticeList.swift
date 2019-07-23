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
    var isBeginning: Bool {
        return true
    }
    
    var nextPageFetchingOperation: PaginatedFetchingOperationType? {
        return nil
    }
    var retryOperation: PaginatedFetchingOperationType? {
        return GetNoticePageOperation(session: session, url: url)
    }
    let session: UserSession
    private let url: URL
    
    init(session: UserSession, url: URL?) {
        self.session = session
        self.url = url ?? ServiceURLs.base.appendingPathComponent("notices")
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        let req = URLRequest(url: url)
        return session.addingAuthorizationToken(to: req)
    }
}

class GetNoticePageOperationFactory: PaginatedFetchingOperationFactoryType {
    
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetNoticePageOperation {
        return GetNoticePageOperation(session: session, url: nil)
    }
}

class Notice {
    let isRead: Bool
    let type: NoticeType
    let date: Date = Date()
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

