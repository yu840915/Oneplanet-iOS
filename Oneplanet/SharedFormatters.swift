//
//  SharedFormatters.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

struct SharedNumberFormatters {
    private init() {}
    
    static let integer: NumberFormatter = {
        let value = NumberFormatter()
        value.numberStyle = .decimal
        value.maximumFractionDigits = 0
        value.roundingMode = .up
        return value
    }()
}
