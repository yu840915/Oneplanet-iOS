//
//  EmailInputValidatorTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class EmailInputValidatorTests: XCTestCase {

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

}
