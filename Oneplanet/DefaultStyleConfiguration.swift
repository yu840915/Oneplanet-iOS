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
        let dimColor = #colorLiteral(red: 0.2901960784, green: 0.2901960784, blue: 0.2901960784, alpha: 1)
        UITabBarItem.appearance()
            .setTitleTextAttributes([.foregroundColor : dimColor, .font: UIFont.systemFont(ofSize: 10, weight: .semibold)],
                                    for: .normal)
        UITabBarItem.appearance()
            .setTitleTextAttributes([.foregroundColor : UIColor.black, .font: UIFont.systemFont(ofSize: 10, weight: .semibold)],
                                    for: .selected)
        UITabBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().backIndicatorImage = UIImage(named: "ic_back_nor")
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = UIImage(named: "ic_back_nor")
    }
}

