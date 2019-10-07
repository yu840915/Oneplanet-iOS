//
//  DefaultStyleConfiguration.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/31.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class DefaultStyleConfiguration {
    class func config() {
        Toast.config()
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black
        shadow.shadowBlurRadius = 2.0
        shadow.shadowOffset = .zero
        UITabBarItem.appearance()
            .setTitleTextAttributes([.foregroundColor : ColorPalette.defaultText, .font: UIFont.systemFont(ofSize: 10, weight: .semibold), .shadow: shadow],
                                    for: .normal)
        let highlightedShadow = NSShadow()
        highlightedShadow.shadowColor = UIColor.red
        highlightedShadow.shadowBlurRadius = 2.0
        highlightedShadow.shadowOffset = .zero
        UITabBarItem.appearance()
            .setTitleTextAttributes([.foregroundColor : ColorPalette.defaultText, .font: UIFont.systemFont(ofSize: 10, weight: .semibold), .shadow: highlightedShadow],
                                    for: .selected)
        if #available(iOS 13.0, *) {
            UITabBar.appearance().standardAppearance.shadowColor = .clear
            UITabBar.appearance().standardAppearance.shadowImage = UIImage()
            UITabBarItem.appearance()
            
        } else {
            UITabBar.appearance().shadowImage = UIImage()
        }
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_back_nor")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_back_nor")
    }
}

