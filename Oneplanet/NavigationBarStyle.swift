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
    static let black = BlackNavigationBarStyle()
    static let darkGrey = DarkGreyNavigationBarStyle()
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

class BlackNavigationBarStyle: NavigationBarStyle {
    override func configure(_ bar: UINavigationBar) {
        bar.barTintColor = .black
        bar.barStyle = .black
        bar.isTranslucent = false
        bar.tintColor = ColorPalette.defaultText
    }
}

class DarkGreyNavigationBarStyle: NavigationBarStyle {
    override func configure(_ bar: UINavigationBar) {
        bar.barTintColor = ColorPalette.greyBar
        bar.barStyle = .black
        bar.isTranslucent = false
        bar.tintColor = ColorPalette.defaultText
        bar.titleTextAttributes = [
            .foregroundColor: ColorPalette.defaultText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
    }
}
