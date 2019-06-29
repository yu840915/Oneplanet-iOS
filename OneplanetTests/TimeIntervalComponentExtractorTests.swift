//
//  TimeIntervalComponentExtractorTests.swift
//  OneplanetTests
//
//  Created by 立宣于 on 2019/6/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import XCTest
@testable import Oneplanet

class TimeIntervalComponentExtractorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExtractSeconds() {
        let extractor = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        
        let comp = extractor.extract(from: 10.0).first
        
        XCTAssertEqual(comp?.unitInterval, .second)
        XCTAssertEqual(comp?.units, 10)
    }
    
    func testExtractMinutes() {
        let extractor = TimeIntervalComponentExtractor(unitInterval: .minute, next: nil)
        
        let comp = extractor.extract(from: 12.0 * .minute + 20 * .second).first
        
        XCTAssertEqual(comp?.unitInterval, .minute)
        XCTAssertEqual(comp?.units, 12)
    }

    func testExtractChainedExtraction() {
        let secExtractor = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let extractor = TimeIntervalComponentExtractor(unitInterval: .minute, next: secExtractor)

        let comps = extractor.extract(from: 12.0 * .minute + 20 * .second)
        
        XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .minute, units: 12)))
        XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .second, units: 20)))
    }
    
    func testFullExtractionChain() {
        
        let secExtractor = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let minExtractor = TimeIntervalComponentExtractor(unitInterval: .minute, next: secExtractor)
        let hrExtractor = TimeIntervalComponentExtractor(unitInterval: .hour, next: minExtractor)
        let extractor = TimeIntervalComponentExtractor(unitInterval: .day, next: hrExtractor)
        
        let comps = extractor.extract(from: 3 * .day + 5 * .hour + 12.0 * .minute + 20 * .second)
        
       XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .day, units: 3)))
        XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .hour, units: 5)))
        XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .minute, units: 12)))
        XCTAssertTrue(comps.contains(TimeIntervalComponent(unitInterval: .second, units: 20)))
    }
    
    func testNegativeInterval() {
        let secExtractor = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let extractor = TimeIntervalComponentExtractor(unitInterval: .minute, next: secExtractor)
        
        let comps = extractor.extract(from: -1 * 12.0 * .minute + 20 * .second)
        
        XCTAssertTrue(comps.isEmpty)
    }
    
    func testTimeIntervalComponents() {
        let secExtractor = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let minExtractor = TimeIntervalComponentExtractor(unitInterval: .minute, next: secExtractor)
        let hrExtractor = TimeIntervalComponentExtractor(unitInterval: .hour, next: minExtractor)
        let extractor = TimeIntervalComponentExtractor(unitInterval: .day, next: hrExtractor)
        
        let components = TimeIntervalComponents(extractor.extract(from: 3 * .day + 5 * .hour + 12.0 * .minute + 20 * .second))
        
        XCTAssertEqual(components.days, 3)
        XCTAssertEqual(components.hours, 5)
        XCTAssertEqual(components.minutes, 12)
        XCTAssertEqual(components.seconds, 20)
    }
}
