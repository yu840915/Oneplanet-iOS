//
//  ChecklistItemTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class ChecklistItemTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testReportFinishedIfPreferenceIsTrue() {
        let pref = FakeBoolPreferencesItem(key: "test")
        pref.fakeValue = true
        let item = ChecklistItem(pref)
        
        XCTAssertTrue(item.isFinished)
    }
    
    func testReportUnfinishedIfPreferenceIsFalse() {
        let pref = FakeBoolPreferencesItem(key: "test")
        pref.fakeValue = false
        let item = ChecklistItem(pref)
        
        XCTAssertFalse(item.isFinished)
    }

    func testReportUnfinishedIfPreferenceNoValue() {
        let item = ChecklistItem(FakeBoolPreferencesItem(key: "test"))
        
        XCTAssertFalse(item.isFinished)
    }
    
    func testMarkNoValueAsFinished() {
        let pref = FakeBoolPreferencesItem(key: "test")
        let item = ChecklistItem(pref)
        
        item.markAsFinished()
        
        XCTAssertEqual(pref.setCounter, 1)
        XCTAssertTrue(item.isFinished)
    }
    
    func testMarkFalseAsFinished() {
        let pref = FakeBoolPreferencesItem(key: "test")
        pref.fakeValue = false
        let item = ChecklistItem(pref)
        
        item.markAsFinished()
        
        XCTAssertTrue(item.isFinished)
    }
}

extension ChecklistItemTests {
    class FakeBoolPreferencesItem: BoolPreferencesItem {
        var fakeValue: Bool?
        private(set) var setCounter = 0
        override var hasValue: Bool {
            return fakeValue != nil
        }
        override var value: Bool? {
            set {
                fakeValue = newValue
                setCounter += 1
            }
            get {
                return fakeValue
            }
        }
    }
}
