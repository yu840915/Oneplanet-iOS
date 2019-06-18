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
    
    func testThrowsIfHasNonEmailCharacters() {
        let validator = EmailCharacterValidator()
        
        XCTAssertThrowsError(try validator.validate("abc><@aa"))
        XCTAssertThrowsError(try validator.validate("a a@123"))
        XCTAssertThrowsError(try validator.validate("中文"))
        XCTAssertThrowsError(try validator.validate("https://www.apple.com"))
    }
    
    func testNotThrowIfOnlyEmailCharacters() {
        let validator = EmailCharacterValidator()
        
        XCTAssertNoThrow(try validator.validate("abc@bb.cc"))
        XCTAssertNoThrow(try validator.validate("abc+1@gmail.com"))
        XCTAssertNoThrow(try validator.validate("abc_def@oneplanet.com"))
        XCTAssertNoThrow(try validator.validate("abc"))
        XCTAssertNoThrow(try validator.validate("abc_def@@@-.oneplanet."))
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
        XCTAssertThrowsError(try validator.validate("a  1"))
        XCTAssertThrowsError(try validator.validate("1  1"))
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
        XCTAssertNoThrow(try validator.validate("1 "))
        XCTAssertNoThrow(try validator.validate("1 2"))
        XCTAssertNoThrow(try validator.validate("1 2 "))
        XCTAssertNoThrow(try validator.validate("a1 "))
        XCTAssertNoThrow(try validator.validate("a1 b2"))
        XCTAssertNoThrow(try validator.validate("a1 b2 "))
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
    
    func testThrowsIfNonEmpty() {
        let validator = EmptyInputValidator()

        XCTAssertThrowsError(try validator.validate(" "))
        XCTAssertThrowsError(try validator.validate("1"))
        XCTAssertThrowsError(try validator.validate("a"))
        XCTAssertThrowsError(try validator.validate("\t"))
    }

    func testNotThrowsIfEmpty() {
        let validator = EmptyInputValidator()
        
        XCTAssertNoThrow(try validator.validate(""))
    }
    
    func testThrowsIfHasNondigit() {
        let validator = DigitInputValidator()
        
        XCTAssertThrowsError(try validator.validate(" "))
        XCTAssertThrowsError(try validator.validate("1a"))
        XCTAssertThrowsError(try validator.validate("a"))
        XCTAssertThrowsError(try validator.validate("\t1"))
        XCTAssertThrowsError(try validator.validate("1 2 3"))
    }

    func testNotThrowsIfDigit() {
        let validator = DigitInputValidator()
        
        XCTAssertNoThrow(try validator.validate("1234567890"))
    }
    
    func testThrowsIfNonRomanName() {
        let validator = RomanNameValidator()
        
        XCTAssertThrowsError(try validator.validate("한글"))
        XCTAssertThrowsError(try validator.validate("王小明"))
        XCTAssertThrowsError(try validator.validate("Хангы́ль"))
        XCTAssertThrowsError(try validator.validate("ハン"))
        XCTAssertThrowsError(try validator.validate("@llen"))
        XCTAssertThrowsError(try validator.validate("123"))
    }
    
    func testNotThrowsIfRomanName() {
        let validator = RomanNameValidator()
        
        XCTAssertNoThrow(try validator.validate("Lee"))
        XCTAssertNoThrow(try validator.validate("Lee "))
        XCTAssertNoThrow(try validator.validate("Peter Alex"))
        XCTAssertNoThrow(try validator.validate("Jr. Peter"))
        XCTAssertNoThrow(try validator.validate("Wang, Peter"))
        XCTAssertNoThrow(try validator.validate("Señora Lisa"))
        XCTAssertNoThrow(try validator.validate("Søfiå Åmy"))
        XCTAssertNoThrow(try validator.validate("Wang-a-ming"))
    }

    func testThrowsIfNonRomanAddress() {
        let validator = RomanAddressValidator()
        
        XCTAssertThrowsError(try validator.validate("한글"))
        XCTAssertThrowsError(try validator.validate("王小明"))
        XCTAssertThrowsError(try validator.validate("Хангы́ль"))
        XCTAssertThrowsError(try validator.validate("ハン"))
        XCTAssertThrowsError(try validator.validate("@llen"))
    }
    
    func testNotThrowsIfRomanAddress() {
        let validator = RomanAddressValidator()
        
        XCTAssertNoThrow(try validator.validate("Rm. a, 3F.-11, No. 6-5, Aly. 12, Ln. 2, Guanghua 3rd Ln., Datun Rd., Beitou Dist., Taipei City 112, Taiwan (R.O.C.)"))
    }
    
    func testThrowsIfNonPhoneNumberCharacters() {
        let validator = PhoneNumberCharacterValidator()
        
        XCTAssertThrowsError(try validator.validate("123a"))
        XCTAssertThrowsError(try validator.validate("123 123"))
    }

    func testNotThrowsIfPhoneNumberCharacters() {
        let validator = PhoneNumberCharacterValidator()
        
        XCTAssertNoThrow(try validator.validate("123#123"))
        XCTAssertNoThrow(try validator.validate("*+#"))
        XCTAssertNoThrow(try validator.validate("*+#12345"))
    }
    
    func testThrowsIfNonTaiwanPhoneNumber() {
        let validator = PhoneNumberValidator()
        let builder = PhoneNumberBuilder(countryCode: nil)
        builder.countryCode = builder.countries.first{$0.isoCountryCode == "TW"}!
        validator.phoneNumberBuilder = builder
        
        XCTAssertThrowsError(try validator.validate("12345678"))
        XCTAssertThrowsError(try validator.validate("3353"))
    }
    
    func testNotThrowsIfTaiwanPhoneNumber() {
        let validator = PhoneNumberValidator()
        let builder = PhoneNumberBuilder(countryCode: nil)
        builder.countryCode = builder.countries.first{$0.isoCountryCode == "TW"}!
        validator.phoneNumberBuilder = builder

        XCTAssertNoThrow(try validator.validate("0912345678"))
        XCTAssertNoThrow(try validator.validate("0800235123"))
        XCTAssertNoThrow(try validator.validate("0222351234#123"))
    }
}
