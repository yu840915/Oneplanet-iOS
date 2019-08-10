//
//  PromotionPageList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class PromotionPageList {
    let pages: [PromotionPage]
    
    init(pages: [PromotionPage]) {
        self.pages = pages
    }
}

class PromotionPage {
    let id: String
    let link: URL?
    let poster: WebImageInfo
    
    init(id: String, link: URL?) {
        self.link = link
        self.id = id
        poster = WebImageInfo(url: ServiceURLs.base.appendingPathComponent("ad/\(id).jpg"))
    }
    
    class func from(_ collectionItem: CollectionItem) -> PromotionPage? {
        guard collectionItem.type.lowercased() == "ad" else {return nil}
        return PromotionPage(id: collectionItem.id, link: collectionItem.link)
    }
}

class GetPromotionPageListOperation: AlamofireAPIAccessOperation {
    private(set) var list: PromotionPageList?
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        var comp = URLComponents(url: ServiceURLs.base.appendingPathComponent("collection/popups"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [URLQueryItem(name: "page", value: "1"),URLQueryItem(name: "limit", value: "20")]
        return session.addingAuthorizationToken(to: URLRequest(url: comp.url!))
    }
    
    override func processData(with data: Data) throws {
        let items = try JSONDecoder.default.decode([CollectionItem].self, from: data)
        list = PromotionPageList(pages: items.compactMap{PromotionPage.from($0)})
    }
}


class CollectionItem: Decodable {
    let id: String
    let type: String
    let link: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case link = "url"
    }
}
