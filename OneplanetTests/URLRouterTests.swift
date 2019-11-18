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
    
    func testQeuryCanHandle() {
        let router = URLRouter()
        var count = 0
        router.add("/hello") { (params) -> Bool in
            count += 1
            return true
        }
        
        XCTAssertTrue(router.canHandle(URL(string: "https://oneplanet.page.link/hello")!))
        XCTAssertFalse(router.canHandle(URL(string: "https://oneplanet.page.link/foo")!))
        XCTAssertEqual(count, 0)
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
    
    func testQeuryCanHandleWithOverridingRouter() {
        let parent = URLRouter()
        var count1 = 0
        parent.add("/hello") { (params) -> Bool in
            count1 += 1
            return true
        }
        let child = URLRouter()
        var count2 = 0
        child.add("/foo") { (params) -> Bool in
            count2 += 1
            return true
        }
        
        parent.addOverridingRouter(child)
        XCTAssertTrue(parent.canHandle(URL(string: "https://oneplanet.page.link/hello")!))
        XCTAssertTrue(parent.canHandle(URL(string: "https://oneplanet.page.link/foo")!))
        XCTAssertFalse(parent.canHandle(URL(string: "https://oneplanet.page.link/bar")!))
        XCTAssertEqual(count1, 0)
        XCTAssertEqual(count2, 0)
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
    
    func testMagicLink() {
        let router = URLRouter()
        var url: URL?
        var link: URL?
        router.add("/") { (params) -> Bool in
            url = params[URLRouter.Keys.url] as? URL
            link = URL(string: params["link"] as? String ?? "")
            return true
        }

        let magicLink = URL(string: "https://theonecollection.page.link/?link=https://api.oneplanet-official.com/login/email?code%3Dfa7c8b531eae45b0a2fc9ec52ab8865d&isi=1410049209&ibi=tw.com.mores.theonecollection.Oneplanet&cid=3903585605462674524&_fpb=CKwGEPcCGgVlbi1VUw==&_cpt=cpit&_iumenbl=1&_iumchkactval=1&_plt=1508&_uit=1927&_cpb=1")!
        router.handle(magicLink)

        XCTAssertEqual(url, magicLink)
        XCTAssertEqual(link?.query, "code=fa7c8b531eae45b0a2fc9ec52ab8865d")
    }
}
