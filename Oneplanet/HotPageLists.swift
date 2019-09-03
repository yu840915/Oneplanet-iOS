//
//  HotPageLists.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class HotItemList: PaginatedList<GetCollectionPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetCollectionPageOperationFactory(session: session, listName: .hot))
    }
}

class BannerItemList: PaginatedList<GetCollectionPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetCollectionPageOperationFactory(session: session, listName: .banners))
    }
}

class GetCollectionPageOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    let listName: GetCollectionPageOperation.ListName
    init(session: UserSession, listName: GetCollectionPageOperation.ListName) {
        self.session = session
        self.listName = listName
    }
    
    func makeInitialOperation() -> GetCollectionPageOperation {
        return GetCollectionPageOperation(session: session, name: listName)
    }
}

class GetCollectionPageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    enum ListName: String {
        case hot = "main"
        case banners
    }
    
    let isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetCollectionPageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    private(set) var items: [CollectionItem] = []
    
    let session: UserSession
    private let url: URL
    convenience init(session: UserSession, name: ListName) {
        self.init(session: session, url: ServiceURLs.devBase.appendingPathComponent("collection/\(name.rawValue)"), isBeginning: true)
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
        nextPageFetchingOperation = GetCollectionPageOperation(session: session, url: url, isBeginning: false)
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([CollectionItem].self, from: data)
    }
}

class CollectionCategoryItem: CollectionItemPreviewing {
    let id: String
    let cover: WebImageInfo
    
    init(id: String, coverURL: URL) {
        self.id = id
        cover = WebImageInfo(url: coverURL)
    }

    class func from(_ collectionItem: CollectionItem) -> CollectionCategoryItem? {
        guard collectionItem.type?.lowercased() == "category" else {return nil}
        return CollectionCategoryItem(id: collectionItem.id, coverURL: collectionItem.thumbnail.toURL())
    }
}

class CollectionProductItem: CollectionItemPreviewing {
    let id: String
    let cover: WebImageInfo

    init(id: String, coverURL: URL) {
        self.id = id
        cover = WebImageInfo(url: coverURL)
    }
    
    class func from(_ collectionItem: CollectionItem) -> CollectionProductItem? {
        guard collectionItem.type == nil || collectionItem.type!.lowercased() == "product" else {return nil}
        return CollectionProductItem(id: collectionItem.id, coverURL: collectionItem.thumbnail.toURL())
    }
}
