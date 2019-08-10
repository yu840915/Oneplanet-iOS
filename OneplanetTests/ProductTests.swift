//
//  ProductTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/8/10.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class ProductTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParseProductOverview() {
        let data = """
    {
        "description": "This is the description of product 1",
        "display_name": "Product 1",
        "name": "product-1"
    }
""".data(using: .utf8)!
        do {
            let overview = try JSONDecoder.default.decode(ProductOverview.self, from: data)
            XCTAssertEqual(overview.description, "This is the description of product 1")
            XCTAssertEqual(overview.displayName, "Product 1")
            XCTAssertEqual(overview.name, "product-1")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseFullProduct() {
        let data = """
{
    "description": "This is the description of product 1",
    "display_name": "Product 1",
    "id": "5d43130c3c02809acf2b5e5e",
    "name": "product-1",
    "images": [
        "http://127.0.0.1:8000/product/5d43130c3c02809acf2b5e5e/5d431c0737c1c9eb861c2a30.jpg",
        "http://127.0.0.1:8000/product/5d43130c3c02809acf2b5e5e/5d431c0737c1c9eb861c2a31.jpg",
        "http://127.0.0.1:8000/product/5d43130c3c02809acf2b5e5e/5d431c0737c1c9eb861c2a32.jpg"
    ]
}
""".data(using: .utf8)!
        do {
            let product = try JSONDecoder.default.decode(Product.self, from: data)
            XCTAssertEqual(product.description, "This is the description of product 1")
            XCTAssertEqual(product.displayName, "Product 1")
            XCTAssertEqual(product.name, "product-1")
            XCTAssertEqual(product.id, "5d43130c3c02809acf2b5e5e")
            XCTAssertEqual(product.images.count, 3)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
