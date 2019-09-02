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
        "name":"product-7",
        "display_name":"Off-White™/Nike® Air Max 90",
        "id":"5d69423ec4e957c193f2a274",
        "thumbnail":"https://storage.googleapis.com/oneplanet-app/off90-2.jpg"
}
""".data(using: .utf8)!
        do {
            let overview = try JSONDecoder.default.decode(ProductOverview.self, from: data)
            XCTAssertEqual(overview.displayName, "Off-White™/Nike® Air Max 90")
            XCTAssertEqual(overview.name, "product-7")
            XCTAssertNotNil(overview.cover)
            XCTAssertEqual(overview.id, "5d69423ec4e957c193f2a274")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseFullProduct() {
        let data = """
    {
        "name":"product-4",
        "categories":["other"],
        "close_at":"2019-10-09T16:00:00.000Z",
        "description":"SEASON FW18\\nCOLOR/SIZE Black/Blue / L\\nRETAIL $575 USD\\nRESELL $650 USD\\nSUPPLIER Hills Select Taipei",
        "display_name":"BAPE Color Camo Reversible PONR Shark Full Zip Hoodie",
        "external_url":"",
        "images":[
            "https://storage.googleapis.com/oneplanet-app/bapesharkblue.jpg",
            "https://storage.googleapis.com/oneplanet-app/bapesharkblue-2.jpg"
        ],
        "is_locked":true,
        "start_at":"2019-08-18T16:00:00.000Z",
        "id":"5d69412ec4e957c193f282a9"
    }
""".data(using: .utf8)!
        do {
            let product = try JSONDecoder.default.decode(Product.self, from: data)
            XCTAssertEqual(product.description, "SEASON FW18\nCOLOR/SIZE Black/Blue / L\nRETAIL $575 USD\nRESELL $650 USD\nSUPPLIER Hills Select Taipei")
            XCTAssertEqual(product.displayName, "BAPE Color Camo Reversible PONR Shark Full Zip Hoodie")
            XCTAssertEqual(product.name, "product-4")
            XCTAssertEqual(product.id, "5d69412ec4e957c193f282a9")
            XCTAssertEqual(product.images.count, 2)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
