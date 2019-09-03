//
//  AuctionSystem.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire



class MyLotList: PaginatedList<GetMyLotPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetMyLotPageOperationFactory(session: session))
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
        var comp = URLComponents(url: ServiceURLs.devBase.appendingPathComponent("products"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [.init(name: "category", value: "shoes")]
        self.init(session: session, url: comp.url!, isBeginning: true)
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

//class BidInfo {
//    let endDate: Date
//    let leadUser: String
//}


