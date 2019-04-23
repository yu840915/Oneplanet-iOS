//
//  UIComponentFactories.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BarButtonItemFactory {
    private init(){}
    static let shared = BarButtonItemFactory()
    
    func makeTitlelessBack() -> UIBarButtonItem {
        return UIBarButtonItem()
    }
}
