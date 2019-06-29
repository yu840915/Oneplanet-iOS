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
    static let clockComponent: NumberFormatter = {
        let result = NumberFormatter()
        result.numberStyle = .decimal
        result.minimumIntegerDigits = 2
        result.maximumFractionDigits = 0
        return result
    }()

}

class RoughNumberFormatter: Formatter {
    private let formatter: NumberFormatter
    
    override init() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        self.formatter = formatter
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        self.formatter = formatter
        super.init(coder: aDecoder)
    }
    
    override func string(for obj: Any?) -> String? {
        return nil
    }
    
    func string(for int: Int) -> String {
        var sigVal = int
        var suffix = ""
        if int >= 10000 {
            sigVal = quotient(form: int, divisor: 1000)
            suffix = "k"
        }
        return (formatter.string(for: sigVal) ?? "") + suffix
    }
    
    private func quotient(form int: Int, divisor: Int) -> Int {
        var result = int / divisor
        if int % divisor >= (divisor / 2) {
            result += 1
        }
        return result
    }
}
