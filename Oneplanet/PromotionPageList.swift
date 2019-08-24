//
//  PromotionPageList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class PromotionPageList {
    let pages: [PromotionAd]
    
    init(pages: [PromotionAd]) {
        self.pages = pages
    }
}

class PromotionAd: CollectionItemPreviewing {
    let id: String
    let link: URL?
    let cover: WebImageInfo
    
    init(id: String, link: URL?) {
        self.link = link
        self.id = id
        cover = WebImageInfo(url: ServiceURLs.base.appendingPathComponent("ad/\(id).jpg"))
    }
    
    class func from(_ collectionItem: CollectionItem) -> PromotionAd? {
        guard collectionItem.type.lowercased() == "ad" else {return nil}
        return PromotionAd(id: collectionItem.id, link: collectionItem.link)
    }
}

class GetPromotionPageListOperation: AlamofireAPIAccessOperation {
    private(set) var list: PromotionPageList?
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        var req = session.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.devBase.appendingPathComponent("popup").addingFirstPageQeury(limit: 20)))
        req.addValue(Localized.languageCode, forHTTPHeaderField: Localized.acceptLanguageKey)
        return req
    }
    
    override func processData(with data: Data) throws {
        let items = try JSONDecoder.default.decode([CollectionItem].self, from: data)
        list = PromotionPageList(pages: items.compactMap{PromotionAd.from($0)})
    }
}

extension URL {
    func addingFirstPageQeury(limit :Int = 10) -> URL {
        var comp = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        let items = [URLQueryItem(name: "page", value: "1"),URLQueryItem(name: "limit", value: "\(limit)")]
        if let existing = comp.queryItems {
            comp.queryItems = items + existing
        } else {
            comp.queryItems = items
        }
        return comp.url!
    }
    
    func addingQ(_ q: String) -> URL {
        var comp = URLComponents(url: self, resolvingAgainstBaseURL: false)!
        let items = [URLQueryItem(name: "q", value: q)]
        if let existing = comp.queryItems {
            comp.queryItems = items + existing
        } else {
            comp.queryItems = items
        }
        return comp.url!
    }
}

protocol CollectionItemPreviewing {
    var cover: WebImageInfo {get}
}

class CollectionItem: Decodable {
    let id: String
    let type: String
    let link: URL?
    
    enum CodingKeys: String, CodingKey {
        case id, type
        case link = "url"
    }
    
    var previewable: CollectionItemPreviewing? {
        return PromotionAd.from(self) ?? CollectionProductItem.from(self) ?? CollectionCategoryItem.from(self)
    }
}
