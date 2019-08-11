//
//  CollectionItemTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class CollectionItemTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseProductItem() {
        let data = """
    {
        "id": "5d46b2f5338f3f58a865a10b",
        "type": "product"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d46b2f5338f3f58a865a10b")
            XCTAssertEqual(item.type, "product")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseAdItem() {
        let data = """
    {
        "id": "5d46b2f5338f3f58a865a10d",
        "type": "ad",
        "url": "https://asdasdasd/"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d46b2f5338f3f58a865a10d")
            XCTAssertEqual(item.type, "ad")
            XCTAssertEqual(item.link, URL(string: "https://asdasdasd/")!)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
