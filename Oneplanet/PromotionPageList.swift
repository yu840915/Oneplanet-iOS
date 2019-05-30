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
    let link: URL?
    let poster: WebImageInfo
    
    init(link: URL?, poster: WebImageInfo) {
        self.link = link
        self.poster = poster
    }
}

class GetPromotionPageListOperation: AlamofireAPIAccessOperation {
    private(set) var list: PromotionPageList?
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: URL(string: "https://www.google.com")!)
    }
    
    override func willFinishProcess() throws {
        list = PromotionPageList(pages: [
            PromotionPage(link: URL(string: "https://www.google.com")!, poster: WebImageInfo(url: URL(string: "https://images.pexels.com/photos/414612/pexels-photo-414612.jpeg?cs=srgb&dl=beautiful-beauty-blue-414612.jpg&fm=jpg")!)),
            PromotionPage(link: nil, poster: WebImageInfo(url: URL(string: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif")!))
            ])
    }
}
