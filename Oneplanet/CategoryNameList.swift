//
//  CategoryNameList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class CategoryName: Decodable {
    let name: String
    let count: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case name
    }
}

class CategoryNameList: PaginatedList<GetCategoryNamePageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetCategoryNamePageOperationFactory(session: session))
    }
}

class GetCategoryNamePageOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetCategoryNamePageOperation {
        return GetCategoryNamePageOperation(session: session)
    }
}

class GetCategoryNamePageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    private(set) var items: [CategoryName] = []
    let isBeginning: Bool
    let session: UserSession
    private let url: URL
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetCategoryNamePageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    
    convenience init(session: UserSession) {
        self.init(session: session, url: ServiceURLs.devBase.appendingPathComponent("categories").addingFirstPageQeury(), isBeginning: true)
    }
    
    init(session: UserSession, url: URL, isBeginning: Bool) {
        self.isBeginning = isBeginning
        self.session = session
        self.url = url
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: url))
    }
    
    private func prepareNextPage(from response: HTTPURLResponse) {
        let finder = WebLinkingKeyMap(links: response.links)
        guard let url = finder.findLink(in: response, for: PageRelation.next) else  {
            return
        }
        nextPageFetchingOperation = GetCategoryNamePageOperation(session: session, url: url, isBeginning: false)
    }

    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([CategoryName].self, from: data)
    }
}
