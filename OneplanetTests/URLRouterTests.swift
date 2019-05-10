//
//  URLRouterTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/4/29.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class URLRouterTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRouting() {
        let router = URLRouter()
        var count = 0
        router.add("/hello") { (params) -> Bool in
            count += 1
            return true
        }
        
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        
        XCTAssertEqual(count, 1)
    }
    
    func testRemoveHandler() {
        let router = URLRouter()
        var count = 0
        router.add("/hello") { (params) -> Bool in
            count += 1
            return true
        }
        
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        router.remove("/hello")
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)

        XCTAssertEqual(count, 1)
    }
    
    func testParseParam() {
        let router = URLRouter()
        var params = [String: Any]()
        router.add("/posts/:id") { (p) -> Bool in
            params = p
            return true
        }
        
        router.handle(URL(string: "https://oneplanet.page.link/posts/123456")!)
        
        XCTAssertNotNil(params["id"])
        if let id = params["id"] as? String {
            XCTAssertEqual(id, "123456")
        }
    }
    
    func testOverridingRouter() {
        let parent = URLRouter()
        var count1 = 0
        parent.add("/hello") { (params) -> Bool in
            count1 += 1
            return true
        }
        let child = URLRouter()
        var count2 = 0
        child.add("/hello") { (params) -> Bool in
            count2 += 1
            return true
        }
        
        parent.addOverridingRouter(child)
        parent.handle(URL(string: "https://oneplanet.page.link/hello")!)

        XCTAssertEqual(count1, 0)
        XCTAssertEqual(count2, 1)
    }
    
    func testLaterOverrideEarlierRouter() {
        let parent = URLRouter()
        var count1 = 0
        parent.add("/hello") { (params) -> Bool in
            count1 += 1
            return true
        }
        let child1 = URLRouter()
        var count2 = 0
        child1.add("/hello") { (params) -> Bool in
            count2 += 1
            return true
        }
        let child2 = URLRouter()
        var count3 = 0
        child2.add("/hello") { (params) -> Bool in
            count3 += 1
            return true
        }
        
        parent.addOverridingRouter(child1)
        parent.addOverridingRouter(child2)
        _ = parent.handle(URL(string: "https://oneplanet.page.link/hello")!)
        
        XCTAssertEqual(count1, 0)
        XCTAssertEqual(count2, 0)
        XCTAssertEqual(count3, 1)
    }
    
    func testRemoveOverriding() {
        let parent = URLRouter()
        var count1 = 0
        parent.add("/hello") { (params) -> Bool in
            count1 += 1
            return true
        }
        let child = URLRouter()
        var count2 = 0
        child.add("/hello") { (params) -> Bool in
            count2 += 1
            return true
        }
        
        parent.addOverridingRouter(child)
        _ = parent.handle(URL(string: "https://oneplanet.page.link/hello")!)
        parent.removeOverridingRouter(child)
        _ = parent.handle(URL(string: "https://oneplanet.page.link/hello")!)

        XCTAssertEqual(count1, 1)
        XCTAssertEqual(count2, 1)
    }
    
    func testCannotAddTwice() {
        let parent = URLRouter()
        let child = URLRouter()
        
        parent.addOverridingRouter(child)
        parent.addOverridingRouter(child)
        
        XCTAssertEqual(parent.overridingRouters.count, 1)
    }
    
    func testCannotAddSelf() {
        let router = URLRouter()
        
        router.addOverridingRouter(router)
        
        XCTAssertEqual(router.overridingRouters.count, 0)
    }
    
    func testWontFireBeforeResume() {
        let router = DelayURLRouter()
        var count = 0
        router.add("/hello") { (params) -> Bool in
            count += 1
            return true
        }

        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        XCTAssertEqual(count, 0)
        router.resume()
        XCTAssertEqual(count, 1)
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        XCTAssertEqual(count, 2)
    }
    
    func  testResumeIsIdempotent() {
        let router = DelayURLRouter()
        var count = 0
        router.add("/hello") { (params) -> Bool in
            count += 1
            return true
        }
        
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        XCTAssertEqual(count, 0)
        router.resume()
        router.resume()
        router.resume()
        XCTAssertEqual(count, 1)
    }
    
    func testCanGetURL() {
        let router = URLRouter()
        var url: URL?
        router.add("/hello") { (params) -> Bool in
            url = params[URLRouter.Keys.url] as? URL
            return true
        }
        
        router.handle(URL(string: "https://oneplanet.page.link/hello")!)
        
        XCTAssertEqual(url, URL(string: "https://oneplanet.page.link/hello")!)
    }
}
