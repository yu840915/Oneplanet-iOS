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
    "id": "5d4f0e6e841fa8edbf790ca3",
    "title": "qwe",
    "user": "5cf93b87a261e132018adbbf",
    "caption": "hello",
    "images": [
      "https://example.com/image-1.jpg",
      "https://example.com/image-2.jpg",
      "https://example.com/image-3.jpg"
    ]
}
""".data(using: .utf8)!
        do {
            let post = try JSONDecoder.default.decode(Post.self, from: data)
            XCTAssertEqual(post.id, "5d4f0e6e841fa8edbf790ca3")
            XCTAssertEqual(post.authorID, "5cf93b87a261e132018adbbf")
            XCTAssertEqual(post.caption, "hello")
            XCTAssertEqual(post.imageURLs.count, 3)
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

}
