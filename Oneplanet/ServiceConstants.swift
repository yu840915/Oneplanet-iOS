//
//  ServiceConstants.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

struct ServiceConstants {
    private init() {}
    
    static var appVersionString: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    static var bundleID: String {
        return Bundle.main.bundleIdentifier!
    }
}

struct ServiceURLs {
    static var base: URL = URL(string: "https://api.oneplanet-official.com")!
    static let appSettings = URL(string:UIApplication.openSettingsURLString)!
    static let terms = URL(string: "https://oneplanet-9e32a.firebaseapp.com/\(Localized.languageCode).html")!
    static let biddingTerms = URL(string: "https://www.google.com")!
}

struct DeepLinks {
    static var blueGemPopUp: URL {
        return ServiceURLs.base.appendingPathComponent("popup/blue-gem")
    }
    static var purpleGemPopUp: URL {
        return ServiceURLs.base.appendingPathComponent("popup/purple-gem")
    }
    static var greenGemPopUp: URL {
        return ServiceURLs.base.appendingPathComponent("popup/green-gem")
    }
    static var hotTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/hot")
    }
    static var liveTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/live")
    }
    static var bidTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/bid")
    }
    static var noticeTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/notice")
    }
    static var meTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/me")
    }
    static var modalEventsPage: URL {
        return ServiceURLs.base.appendingPathComponent("modal/events")
    }
}

extension JSONDecoder {
    static let `default` = JSONDecoder()
}
