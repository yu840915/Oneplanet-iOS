//
//  GenericAppError.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class GenericAppError: NSError {
    init(_ message: String, code: Int = -1) {
        super.init(domain: ServiceConstants.bundleID, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
}
