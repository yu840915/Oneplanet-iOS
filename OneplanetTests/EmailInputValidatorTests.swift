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
    
    func testThrowsIfInputLenghtNotInRange() {
        let validator = InputLengthValidator(min: 4, max: 8)
        
        XCTAssertThrowsError(try validator.validate(""))
        XCTAssertThrowsError(try validator.validate("1"))
        XCTAssertThrowsError(try validator.validate("123"))
        XCTAssertThrowsError(try validator.validate("一二三"))
        XCTAssertThrowsError(try validator.validate("   "))
        XCTAssertThrowsError(try validator.validate("123456789"))
        XCTAssertThrowsError(try validator.validate("一二三四五六七八九"))
        XCTAssertThrowsError(try validator.validate("         "))
    }

    func testNotThrowIfInputLenghtInRange() {
        let validator = InputLengthValidator(min: 4, max: 8)
        
        XCTAssertNoThrow(try validator.validate("1234"))
        XCTAssertNoThrow(try validator.validate("一二三四"))
        XCTAssertNoThrow(try validator.validate("    "))
        XCTAssertNoThrow(try validator.validate("12345678"))
        XCTAssertNoThrow(try validator.validate("一二三四五六七八"))
        XCTAssertNoThrow(try validator.validate("        "))
    }
    
    func testThrowsIfInputHasNoContents() {
        let validator = NonEmptyInputValidator()
        
        XCTAssertThrowsError(try validator.validate(""))
        XCTAssertThrowsError(try validator.validate(" "))
        XCTAssertThrowsError(try validator.validate("    "))
        XCTAssertThrowsError(try validator.validate("\t\r\n "))
    }
    
    func testNotThrowIfInputHasContents() {
        let validator = NonEmptyInputValidator()
        
        XCTAssertNoThrow(try validator.validate(" 1"))
        XCTAssertNoThrow(try validator.validate(" 2"))
        XCTAssertNoThrow(try validator.validate("    3"))
        XCTAssertNoThrow(try validator.validate("\t\r\n 4"))
    }
    
    func testThrowsIfInputIsInvalidNickname() {
        let validator = NicknameInputValidator()
        
        XCTAssertThrowsError(try validator.validate("a  b"))
        XCTAssertThrowsError(try validator.validate("a     b"))
        XCTAssertThrowsError(try validator.validate("a  "))
        XCTAssertThrowsError(try validator.validate("a \tb"))
        XCTAssertThrowsError(try validator.validate("a\t\tb"))
        XCTAssertThrowsError(try validator.validate("a\nb"))
        for s in ["！","＠","＃","＄","％","＾","_","→","😀","(","✓","℃"] {
            XCTAssertThrowsError(try validator.validate("a\(s)b"))
        }
    }
    
    func testNotThrowsIfInputIsValidNickname() {
        let validator = NicknameInputValidator()
        
        XCTAssertNoThrow(try validator.validate("a "))
        XCTAssertNoThrow(try validator.validate("a b"))
        XCTAssertNoThrow(try validator.validate("a b "))
        XCTAssertNoThrow(try validator.validate("abc def"))
        XCTAssertNoThrow(try validator.validate("abc def "))
        XCTAssertNoThrow(try validator.validate("silábicos pueden"))
        XCTAssertNoThrow(try validator.validate("silábicos pueden "))
        XCTAssertNoThrow(try validator.validate("中文 名字"))
        XCTAssertNoThrow(try validator.validate("中文 名字 "))
        XCTAssertNoThrow(try validator.validate("한글 한글"))
        XCTAssertNoThrow(try validator.validate("한글 한글 "))
        XCTAssertNoThrow(try validator.validate("ハン グル"))
        XCTAssertNoThrow(try validator.validate("ハン グル "))
        XCTAssertNoThrow(try validator.validate("Хангы́ль чосонгы́ль"))
        XCTAssertNoThrow(try validator.validate("Хангы́ль чосонгы́ль "))
        XCTAssertNoThrow(try validator.validate("abc中文"))
    }
}
