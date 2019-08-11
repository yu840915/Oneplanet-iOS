//
//  WebLinkingKeyMap.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class WebLinkingKeyMap {
    let map: [String: String]
    init(links: [Link]) {
        var dict = [String: String]()
        links.compactMap{$0.relationType}.forEach{ rel in
            let fragments = rel.components(separatedBy: " ")
            fragments.forEach{ frag in dict[frag] = rel }
            dict[rel] = rel
        }
        map = dict
    }
    
    func findKey(for keyFrag: String) -> String? {
        return map[keyFrag]
    }
    
    func findLink(in response: HTTPURLResponse, for keyFrag: String) -> URL? {
        guard let rel = findKey(for: PageRelation.next),
            let link = response.findLink(relation: rel) else  {
                return nil
        }
        return URL(string: link.uri)
    }
}

struct PageRelation {
    static let first = "first"
    static let previous = "previous"
    static let next = "next"
    static let last = "last"
}
