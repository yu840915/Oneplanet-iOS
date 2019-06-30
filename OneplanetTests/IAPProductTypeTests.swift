//
//  IAPProductTypeTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/6/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class IAPProductTypeTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIdentifyUnlockProduct() {
        let type = IAPProductType.from("Bidding_qualificationAA")
        
        XCTAssertEqual(type, .unlock)
    }
    
    func testIdentifyBidProduct() {
        let type = IAPProductType.from("Bidding_placardAA")
        
        XCTAssertEqual(type, .bid)
    }
    
    func testIdentifyRubyProducts() {
        XCTAssertEqual(IAPProductType.from("ruby"), .ruby)
        XCTAssertEqual(IAPProductType.from("ruby_10pack"), .ruby)
        XCTAssertEqual(IAPProductType.from("ruby_50pack"), .ruby)
        XCTAssertEqual(IAPProductType.from("ruby_100pack"), .ruby)
    }
    
    func testIdentifyFutureRubyProduct() {
        XCTAssertEqual(IAPProductType.from("ruby123_pack"), .ruby)
    }
    
    func testUnknownProductID() {
        XCTAssertNil(IAPProductType.from("t-shirt"))
    }
}
