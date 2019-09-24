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

struct IAPProductIdentifiers {
    static let unlock = "Bidding_qualificationAA"
    static let bid = "Bidding_placardAA"
}

struct ServiceURLs {
//    static var base: URL = URL(string: "https://api.oneplanet-official.com")!
    static var base: URL = devBase
    static var devBase: URL = URL(string:
        "https://oneplanet-api.herokuapp.com")!
    static let appSettings = URL(string:UIApplication.openSettingsURLString)!
    static let terms = URL(string: "https://oneplanet-9e32a.firebaseapp.com/\(Localized.languageCode).html")!
    static var biddingTerms: URL {
        return appConfiguration.biddingTermURL.value ?? URL(string: "https://oneplanet-9e32a.firebaseapp.com/\(Localized.languageCode).html")!
    }
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
    static var lifeTab: URL {
        return ServiceURLs.base.appendingPathComponent("tab/life")
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
    static var categoryList: URL {
        return ServiceURLs.base.appendingPathComponent("category")
    }
    static var categoryListPattern: URL {
        return ServiceURLs.base.appendingPathComponent("category/:query")
    }
    static var modalEventsPage: URL {
        return ServiceURLs.base.appendingPathComponent("modal/events")
    }
    static var shippingInfo: URL {
        return ServiceURLs.base.appendingPathComponent("modal/shipping-info")
    }
    static var postEditor: URL {
        return ServiceURLs.base.appendingPathComponent("modal/post-editor")
    }
    static var followerList: URL {
        return ServiceURLs.base.appendingPathComponent("modal/followers")
    }
    static var followingList: URL {
        return ServiceURLs.base.appendingPathComponent("modal/followings")
    }
}

extension JSONDecoder {
    static let `default`: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(SharedDateFormatters.serverDate)
        return decoder
    }()
}
