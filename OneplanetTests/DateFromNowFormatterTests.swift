//
//  DateFromNowFormatterTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/7/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class DateFromNowFormatterTests: XCTestCase {
    
    var refDate: Date = Date(timeIntervalSince1970: 1563328245)
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFormatSecond() {
        let formatter = DateFromNowFormatter()
        let to1 = refDate.addingTimeInterval(-1)
        let to2 = refDate.addingTimeInterval(-59)
        
        let val1 = formatter.string(from: to1, since: refDate)
        let val2 = formatter.string(from: to2, since: refDate)
        
        XCTAssertEqual(val1, String(format: Localized.phraseFormats.secondsAgoShort, "1"))
        XCTAssertEqual(val2, String(format: Localized.phraseFormats.secondsAgoShort, "59"))
    }

    func testFormatMinutes() {
        let formatter = DateFromNowFormatter()
        let to1 = refDate.addingTimeInterval(-1 * .minute)
        let to2 = refDate.addingTimeInterval(-(1 * .minute + 59 * .second))
        let to3 = refDate.addingTimeInterval(-59 * .minute)
        let to4 = refDate.addingTimeInterval(-(1 * .minute + 1 * .second))

        let val1 = formatter.string(from: to1, since: refDate)
        let val2 = formatter.string(from: to2, since: refDate)
        let val3 = formatter.string(from: to3, since: refDate)
        let val4 = formatter.string(from: to4, since: refDate)
        
        XCTAssertEqual(val1, String(format: Localized.phraseFormats.minutesAgoShort, "1"))
        XCTAssertEqual(val2, String(format: Localized.phraseFormats.minutesAgoShort, "1"))
        XCTAssertEqual(val3, String(format: Localized.phraseFormats.minutesAgoShort, "59"))
        XCTAssertEqual(val4, String(format: Localized.phraseFormats.minutesAgoShort, "1"))
    }
    
    func testFormatHours() {
        let formatter = DateFromNowFormatter()
        let to1 = refDate.addingTimeInterval(-1 * .hour)
        let to2 = refDate.addingTimeInterval(-(1 * .hour + 59 * .second))
        let to3 = refDate.addingTimeInterval(-23 * .hour)
        let to4 = refDate.addingTimeInterval(-(1 * .hour + 1 * .minute + 1 * .second))
        let to5 = refDate.addingTimeInterval(-24 * .hour)
        
        let val1 = formatter.string(from: to1, since: refDate)
        let val2 = formatter.string(from: to2, since: refDate)
        let val3 = formatter.string(from: to3, since: refDate)
        let val4 = formatter.string(from: to4, since: refDate)
        let val5 = formatter.string(from: to5, since: refDate)
        
        XCTAssertEqual(val1, String(format: Localized.phraseFormats.hoursAgoShort, "1"))
        XCTAssertEqual(val2, String(format: Localized.phraseFormats.hoursAgoShort, "1"))
        XCTAssertEqual(val3, String(format: Localized.phraseFormats.hoursAgoShort, "23"))
        XCTAssertEqual(val4, String(format: Localized.phraseFormats.hoursAgoShort, "1"))
        XCTAssertNotEqual(val5, String(format: Localized.phraseFormats.hoursAgoShort, "24"))
    }
}
