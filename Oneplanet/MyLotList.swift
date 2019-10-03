//
//  MyLotList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class MyLotList: PaginatedList<GetMyLotPageOperationFactory> {
    private var additionalUnlockedProductIDs = Set<String>()
    
    init(session: UserSession) {
        super.init(operationFactory: GetMyLotPageOperationFactory(session: session))
    }
    
    func contains(_ product: ProductOverview) -> Bool {
        return items.contains{$0.id == product.id}
    }
    
    func isLocked(_ product: ProductOverview) -> Bool {
        return !(contains(product) || additionalUnlockedProductIDs.contains(product.id))
    }
    
    func markAsUnlocked(_ product: ProductOverview) {
        additionalUnlockedProductIDs.insert(product.id)
    }
}

class GetMyLotPageOperationFactory: PaginatedFetchingOperationFactoryType {
    private weak var session: UserSession!
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetMyLotPageOperation {
        return GetMyLotPageOperation(session: session)
    }
}

class GetMyLotPageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    let isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetMyLotPageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    private(set) var items: [ProductOverview] = []
    let session: UserSession
    private let url: URL
    
    convenience init(session: UserSession) {
        if session.isAdmin {
            self.init(session: session, url: ServiceURLs.base.appendingPathComponent("products/all"), isBeginning: true)
        } else {
            self.init(session: session, url: ServiceURLs.base.appendingPathComponent("products/unlocks"), isBeginning: true)
        }
    }
    
    init(session: UserSession, url: URL, isBeginning: Bool) {
        self.isBeginning = isBeginning
        self.session = session
        self.url = url
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: url))
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
        nextPageFetchingOperation = GetMyLotPageOperation(session: session, url: url, isBeginning: false)
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([ProductOverview].self, from: data)
    }
}
