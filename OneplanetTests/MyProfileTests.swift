//
//  MyProfileTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/5/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class MyProfileTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecoding() {
        let data = """
{
    "id": "AD123FDF13",
    "username": "zcjwmsj168",
    "display_name": "Mike 123",
    "avatar": "https://www.google.com"
}
""".data(using: .utf8)!
        do {
            let profile = try JSONDecoder.default.decode(MyProfile.self, from: data)
            XCTAssertEqual(profile.id, "AD123FDF13")
            XCTAssertEqual(profile.username, "zcjwmsj168")
            XCTAssertEqual(profile.nickname, "Mike 123")
            XCTAssertEqual(profile.avatar?.url, URL(string: "https://www.google.com")!)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testDecodeMissingOptionalValues() {
        let data = """
{
    "id": "AD123FDF13",
    "username": "zcjwmsj168",
    "avatar": "https://www.google.com"
}
""".data(using: .utf8)!
        do {
            let profile = try JSONDecoder.default.decode(MyProfile.self, from: data)
            XCTAssertEqual(profile.id, "AD123FDF13")
            XCTAssertEqual(profile.username, "zcjwmsj168")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
}
