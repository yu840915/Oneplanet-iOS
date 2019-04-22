//
//  NavigationBarStyle.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class NavigationBarStyle {
    static let translucent = TranslucentNavigationBarStyle()
    fileprivate init() {}
    func configure(_ bar: UINavigationBar) {
    }
}

class TranslucentNavigationBarStyle: NavigationBarStyle {
    override func configure(_ bar: UINavigationBar) {
        bar.shadowImage = UIImage()
        bar.barTintColor = .clear
        bar.isTranslucent = true
        bar.setBackgroundImage(UIImage(), for: .default)
    }
}
