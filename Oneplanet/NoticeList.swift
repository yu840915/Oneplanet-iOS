//
//  NoticeList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

//class GetNoticePageOperation: AlamofireAPIAccessOperation {
//    let session: UserSession
//    
//    ini
//    
//    override func prepareURLRequest() throws -> URLRequest {
//        
//    }
//}

class Notice {
    let isRead: Bool
    let type: NoticeType
    let date: Date = Date()
    init(type: NoticeType, isRead: Bool) {
        self.type = type
        self.isRead = isRead
    }
}

enum NoticeType {
    case likeFromOfficialAccount
    case giftFromOfficialAccount
    case followNotice
    case postReported
    case profileReported
}

