//
//  PostTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/8/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class PostTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParsePost() {
        let data = """
{
    "caption":"this is caption",
    "created_at":"2019-09-10T19:13:30.691Z",
    "images":["https://storage.googleapis.com/oneplanet-app-images/hpfo.jpg"],
    "title":"this is title",
    "type":"score",
    "user":"5d77754f4b9d042edcc6f4e4",
    "id":"5d77f5da2dbef8480f23607e"
}
""".data(using: .utf8)!
        do {
            let post = try JSONDecoder.default.decode(Post.self, from: data)
            XCTAssertEqual(post.id, "5d77f5da2dbef8480f23607e")
            XCTAssertEqual(post.authorID, "5d77754f4b9d042edcc6f4e4")
            XCTAssertEqual(post.caption, "this is caption")
            XCTAssertEqual(post.imageURLs.count, 1)
            XCTAssertEqual(post.createdAt, SharedDateFormatters.serverDate.date(from: "2019-09-10T19:13:30.691Z"))
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testParseServerDate() {
        XCTAssertNotNil(SharedDateFormatters.serverDate.date(from: "2019-09-10T19:13:30.691Z"))
    }
}
