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
}

struct ServiceURLs {
    static var base: URL = URL(string: "https://api.oneplanet.live")!
    static let appSettings = URL(string:UIApplication.openSettingsURLString)!
}
