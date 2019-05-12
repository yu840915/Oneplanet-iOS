//
//  RoughNumberFormatterTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/5/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class RoughNumberFormatterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFormattingNumbersLessThanTenK() {
        let formatter = RoughNumberFormatter()
        
        XCTAssertEqual(formatter.string(for: 0), "0")
        XCTAssertEqual(formatter.string(for: 9), "9")
        XCTAssertEqual(formatter.string(for: 99), "99")
        XCTAssertEqual(formatter.string(for: 999), "999")
        XCTAssertEqual(formatter.string(for: 9999), "9,999")
    }

    func testFormattingNumbersBetweenTenKandTenM() {
        let formatter = RoughNumberFormatter()
        
        XCTAssertEqual(formatter.string(for: 10000), "10k")
        XCTAssertEqual(formatter.string(for: 90000), "90k")
        XCTAssertEqual(formatter.string(for: 99499), "99k")
        XCTAssertEqual(formatter.string(for: 99500), "100k")
        XCTAssertEqual(formatter.string(for: 999499), "999k")
        XCTAssertEqual(formatter.string(for: 999500), "1,000k")
        XCTAssertEqual(formatter.string(for: 9999499), "9,999k")
    }

}
