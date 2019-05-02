//
//  EmailAuthCredentialTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class EmailAuthCredentialTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNotifyChanges() {
        let cred = EmailAuthCredential()
        var count = 0
        let handle = cred.inputDidChangeHandlers.add {
            count += 1
        }
        
        cred.email = "abc"
        cred.password = "123"
        
        XCTAssertEqual(count, 2)
    }
}
