//
//  TimeIntervalComponents.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

struct TimeIntervalComponents {
    var seconds: Int
    var minutes: Int
    var hours: Int
    var days: Int
    init(_ components: [TimeIntervalComponent]) {
        var map: [TimeInterval: Int] = [:]
        components.forEach{map[$0.unitInterval] = $0.units}
        seconds = map[.second] ?? 0
        minutes = map[.minute] ?? 0
        hours = map[.hour] ?? 0
        days = map[.day] ?? 0
    }
}

struct TimeIntervalComponent: Equatable {
    let unitInterval: TimeInterval
    let units: Int
}

class TimeIntervalComponentExtractor {
    let unitInterval: TimeInterval
    let next: TimeIntervalComponentExtractor?
    init(unitInterval: TimeInterval, next: TimeIntervalComponentExtractor?) {
        self.unitInterval = unitInterval
        self.next = next
    }
    
    func extract(from interval: TimeInterval) -> [TimeIntervalComponent] {
        guard interval > 0 else { return [] }
        let units = Int((interval / unitInterval).rounded(.towardZero))
        let result = [TimeIntervalComponent(unitInterval: unitInterval, units: units)]
        if let next = self.next {
            let remainder = interval - TimeInterval(units) * unitInterval
            return next.extract(from: remainder) + result
        }
        return result
    }
}
