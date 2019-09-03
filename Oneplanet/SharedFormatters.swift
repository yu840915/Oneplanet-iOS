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
    static let roughNumber = RoughNumberFormatter()
    static let wallet: NumberFormatter = {
        let value = NumberFormatter()
        value.numberStyle = .decimal
        value.maximumFractionDigits = 0
        value.maximumIntegerDigits = 4
        value.minimumIntegerDigits = 4
        value.roundingMode = .up
        value.groupingSeparator = ""
        return value
    }()
}

struct SharedDateFormatters {
    static let serverDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZ"
       return formatter
    }()
}

struct SharedSpeciaFormatters {
    static let dateFromNowForNotices: DateFromNowFormatter = DateFromNowFormatter()
    static let dateFromNowForPosts: DateFromNowFormatter = {
       let formatter = DateFromNowFormatter()
        formatter.style = .long
        return formatter
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
        if let int = obj as? Int {
            return string(for: int)
        }
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

class DateFromNowFormatter: Formatter {
    var style: Style = .short
    private let numberFormatter: NumberFormatter = {
        let value = NumberFormatter()
        value.numberStyle = .decimal
        value.maximumFractionDigits = 0
        value.roundingMode = .up
        return value
    }()
    private let dateFormatter: DateFormatter = {
        let val = DateFormatter()
        val.dateStyle = .short
        return val
    }()
    private var secondFormat: String {
        return style == .short ? Localized.phraseFormats.secondsAgoShort : Localized.phraseFormats.secondsAgo
    }
    private var hourFormat: String {
        return style == .short ? Localized.phraseFormats.hoursAgoShort : Localized.phraseFormats.hoursAgo
    }
    private var minuteFormat: String {
        return style == .short ? Localized.phraseFormats.minutesAgoShort : Localized.phraseFormats.minutesAgo
    }
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        let hour = TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
        return TimeIntervalComponentExtractor(unitInterval: .day, next: hour)
    }()

    func string(from date: Date, since from: Date) -> String {
        let interval = from.timeIntervalSince(date)
        let comps = TimeIntervalComponents(extractor.extract(from: interval))
        if comps.days > 0 {
            return dateFormatter.string(from: date)
        } else if comps.hours > 0 {
            return String(format: hourFormat, numberFormatter.string(for: comps.hours)!)
        } else if comps.minutes > 0 {
            return String(format: minuteFormat, numberFormatter.string(for: comps.minutes)!)
        } else {
            return String(format: secondFormat, numberFormatter.string(for: interval)!)
        }
    }
    
    func string(from date: Date) -> String {
        return string(from: date, since: Date())
    }
    
    enum Style {
        case short
        case long
    }
}
