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

    func testParseItemMissingType() {
        let data = """
    {
        "name":"product-8",
        "id":"5d694297c4e957c193f2ac58",
        "thumbnail":"https://storage.googleapis.com/oneplanet-app/hbswa.jpg"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d694297c4e957c193f2ac58")
            XCTAssertEqual(item.thumbnail, "https://storage.googleapis.com/oneplanet-app/hbswa.jpg")
            XCTAssertNil(item.type)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseProductItem() {
        let data = """
    {
        "name":"product-1",
        "external_url":"https://asdasdasd/",
        "id":"5d693eeac4e957c193f23fad",
        "thumbnail":"https://storage.googleapis.com/oneplanet-app/hbear.jpg",
        "type":"product"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d693eeac4e957c193f23fad")
            XCTAssertEqual(item.type, "product")
            XCTAssertEqual(item.name, "product-1")
            XCTAssertEqual(item.link, URL(string: "https://asdasdasd/")!)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseProductItemWithoutLink() {
        let data = """
    {
        "name":"product-1",
        "external_url":"",
        "id":"5d693eeac4e957c193f23fad",
        "thumbnail":"https://storage.googleapis.com/oneplanet-app/hbear.jpg",
        "type":"product"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d693eeac4e957c193f23fad")
            XCTAssertEqual(item.type, "product")
            XCTAssertEqual(item.name, "product-1")
            XCTAssertNil(item.link)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseCategoryItem() {
        let data = """
    {
        "name":"shoes",
        "id":"5d629b25c4e957c1934d6312",
        "thumbnail":"https://storage.googleapis.com/oneplanet-app/bearbrick.jpg",
        "type":"category"
    }
""".data(using: .utf8)!
        
        do {
            let item = try JSONDecoder.default.decode(CollectionItem.self, from: data)
            XCTAssertEqual(item.id, "5d629b25c4e957c1934d6312")
            XCTAssertEqual(item.type, "category")
            XCTAssertEqual(item.name, "shoes")
            XCTAssertNil(item.link)
            
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
