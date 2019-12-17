//
//  tests.swift
//  JSONParserTests
//
//  Created by Eric Cote on 2019-12-15.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation
import JSONParser
import XCTest

class Tests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testBools() throws {
        XCTAssertTrue(try JSONParser.parse("true") as! Bool)
        XCTAssertFalse(try JSONParser.parse("false") as! Bool)
    }
    
    func testNull() throws {
        XCTAssertNil(try JSONParser.parse("null"))
    }
    
    func testNumber() throws {
        let container = try JSONParser.parse("-12345.12345") as! Double
        XCTAssertEqual(container, -12345.12345)
    }
    
    func testStringOnly() throws {
        let s = "\"json parsing 👌 \\\"  \""
        let container = try JSONParser.parse(s) as! String
        XCTAssertEqual(container, "json parsing 👌 \"  ")
    }

    func testSimpleJSON() throws {
        let jsonPath = Bundle(for: type(of: self)).path(forResource: "test", ofType: "json")!
        let json = try String(contentsOfFile: jsonPath)
        let container = try JSONParser.parse(json) as! Array<Any?>
        let firstObject = container[0] as! Dictionary<String, Any?>
        XCTAssertEqual(firstObject["_id"] as! String, "5df6e4c2689b2ad6546b9b66")
    }

    func testPerformanceExample() throws {
        let jsonPath = Bundle(for: type(of: self)).path(forResource: "test", ofType: "json")!
        let json = try String(contentsOfFile: jsonPath)
        measure {
            do {
                _ = try JSONParser.parse(json)
            } catch {
                print(error)
            }
            
        }
    }

}

