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
    
    init(id: String, imageURL: URL, link: URL?) {
        self.link = link
        self.id = id
        cover = WebImageInfo(url: imageURL)
    }
    
    class func from(_ collectionItem: CollectionItem) -> PromotionAd? {
        guard collectionItem.type?.lowercased() == "ad" else {return nil}
        return PromotionAd(id: collectionItem.id, imageURL: URL(string: collectionItem.thumbnail.toURLCompatible())!, link: collectionItem.link)
    }
    
    class func from(_ item: PopUpItem) -> PromotionAd {
        return PromotionAd(id: item.id, imageURL: URL(string: item.thumbnail.toURLCompatible())!, link: item.link)
    }
}

extension String {
    func toURLCompatible() -> String {
        return replacingOccurrences(of: " ", with: "%20")
    }
    func toURL() -> URL {
        return URL(string: toURLCompatible())!
    }
}

class GetPromotionPageListOperation: AlamofireAPIAccessOperation {
    private(set) var list: PromotionPageList?
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        var req = session.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.devBase.appendingPathComponent("collection/popups").addingFirstPageQeury(limit: 20)))
        req.addValue(Localized.languageCode, forHTTPHeaderField: Localized.acceptLanguageKey)
        return req
    }
    
    override func processData(with data: Data) throws {
        let items = try JSONDecoder.default.decode([PopUpItem].self, from: data)
        list = PromotionPageList(pages: items.map{PromotionAd.from($0)})
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

class PopUpItem: Decodable {
    let id: String
    let thumbnail: String
    let link: URL?

    enum CodingKeys: String, CodingKey {
        case id, thumbnail
        case link = "url"
    }
}

class CollectionItem: Decodable {
    let id: String
    let name: String
    let type: String?
    let thumbnail: String
    var link: URL? {
        if let url = externalURL {
            return URL(string: url)
        }
        return nil
    }
    private let externalURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, thumbnail, name
        case externalURL = "external_url"
    }
    
    var previewable: CollectionItemPreviewing? {
        return CollectionCategoryItem.from(self) ??
            CollectionProductItem.from(self)
    }
}
