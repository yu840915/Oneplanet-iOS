//
//  InputValidatorTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class InputValidatorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThrowsIfEmailIsInvalid() {
        let validator = EmailInputValidator()
        
        XCTAssertThrowsError(try validator.validate("abc@aa"))
        XCTAssertThrowsError(try validator.validate("aa"))
        XCTAssertThrowsError(try validator.validate(""))
        XCTAssertThrowsError(try validator.validate("https://www.apple.com"))
    }
    
    func testNotThrowIfEmailIsValid() {
        let validator = EmailInputValidator()
        
        XCTAssertNoThrow(try validator.validate("abc@bb.cc"))
        XCTAssertNoThrow(try validator.validate("abc+1@gmail.com"))
        XCTAssertNoThrow(try validator.validate("abc_def@oneplanet.com"))
    }
    
    func testThrowsIfNonAlphanumerics() {
        let validator = AlphanumericInputValidator()

        XCTAssertThrowsError(try validator.validate("abc@aa"))
        XCTAssertThrowsError(try validator.validate("好"))
        XCTAssertThrowsError(try validator.validate("español"))
        XCTAssertThrowsError(try validator.validate("ab c"))
        XCTAssertThrowsError(try validator.validate(""))
    }

    func testNotThrowIfAlphanumerics() {
        let validator = AlphanumericInputValidator()
        
        XCTAssertNoThrow(try validator.validate("abc123"))
        XCTAssertNoThrow(try validator.validate("abc"))
        XCTAssertNoThrow(try validator.validate("a"))
        XCTAssertNoThrow(try validator.validate("0"))
        XCTAssertNoThrow(try validator.validate("123"))
    }
}
