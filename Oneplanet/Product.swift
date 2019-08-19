//
//  Product.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class ProductOverview: Decodable {
    let description: String
    let name: String
    let displayName: String
    var cover: WebImageInfo {
        return WebImageInfo(url: ServiceURLs.base.appendingPathComponent("product/\(name)"))
    }
    
    enum CodingKeys: String, CodingKey {
        case description, name
        case displayName = "display_name"
    }
}

class Product: ProductOverview {
    let id: String
    let images: [WebImageInfo]
    
    enum AdditionalKeys: String, CodingKey {
        case id, images
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AdditionalKeys.self)
        id = try container.decode(String.self, forKey: .id)
        images = try container.decode([URL].self, forKey: .images).map{WebImageInfo(url: $0)}
        try super.init(from: decoder)
    }
}

class GetProductDetailOperation: AlamofireAPIAccessOperation {
    let session: UserSession
    let query: String
    private(set) var product: Product?
    var retryOperation: GetProductDetailOperation {
        return GetProductDetailOperation(query: query, session: session)
    }
    
    init(query: String, session: UserSession) {
        self.session = session
        self.query = query
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("product/\(query)")))
    }
    
    override func processData(with data: Data) throws {
        product = try JSONDecoder.default.decode(Product.self, from: data)
    }
}

class CategoryList: PaginatedList<GetProductCagegoryPageOperationFactory> {
    let query: String
    init(session: UserSession, query: String) {
        self.query = query
        super.init(operationFactory: GetProductCagegoryPageOperationFactory(session: session, query: query))
    }
}

class GetProductCagegoryPageOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    let query: String
    init(session: UserSession, query: String) {
        self.session = session
        self.query = query
    }
    
    func makeInitialOperation() -> GetProductCagegoryPageOperation {
        return GetProductCagegoryPageOperation(session: session, query: query)
    }
}

class GetProductCagegoryPageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    let isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetProductCagegoryPageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    private(set) var items: [ProductOverview] = []

    let session: UserSession
    private let url: URL
    
    convenience init(session: UserSession, query: String) {
        self.init(session: session, url: ServiceURLs.base.appendingPathComponent("category/\(query)").addingFirstPageQeury(), isBeginning: true)
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
        nextPageFetchingOperation = GetProductCagegoryPageOperation(session: session, url: url, isBeginning: false)
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([ProductOverview].self, from: data)
    }
}


