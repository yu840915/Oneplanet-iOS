//
//  BidOutcomeHistory.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class BidOutcomeHistory: PaginatedList<GetBidOutcomeHistoryPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetBidOutcomeHistoryPageOperationFactory(session: session))
    }
}

class GetBidOutcomeHistoryPageOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetBidOutcomeHistoryPageOperation {
        let url = ServiceURLs.base.appendingPathComponent("bidding/history").addingFirstPageQeury()
        return GetBidOutcomeHistoryPageOperation(session: session, url: url, isBeginning: true)
    }
}

class GetBidOutcomeHistoryPageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    let isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetBidOutcomeHistoryPageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    var items: [BidProductOverview] = []
    
    let session: UserSession
    private let url: URL

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
        nextPageFetchingOperation = GetBidOutcomeHistoryPageOperation(session: session, url: url, isBeginning: false)
    }

    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([BidProductOverview].self, from: data)
    }
}

class BidProductOverview: ProductOverview {
    let shippingStates: ShippingStates?
    
    required init(from decoder: Decoder) throws {
        shippingStates = try? ShippingStates(from: decoder)
        try super.init(from: decoder)
    }
}

class ShippingStates: Decodable {
    let isShipped: Bool
    let shippingState: String?
    let trackingNumber: String?
    let trackingURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case isShipped = "shipped"
        case shippingState = "shipping_state"
        case trackingNumber = "shipping_no"
        case trackingURL = "track_shipment_url"
    }
}
