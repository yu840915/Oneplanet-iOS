//
//  User.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class Race {
    let color: UIColor
    let avatar: UIImage
    init(color: UIColor, avatar: UIImage) {
        self.color = color
        self.avatar = avatar
    }
}

class WebImage {
    let url: URL
    let accessToken: String?
    init(url: URL, accessToken: String?) {
        self.url = url
        self.accessToken = accessToken
    }
}
