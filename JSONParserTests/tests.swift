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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimpleJSON() throws {
        let json = "{ \"userId\": 1, \"id\": 1.1, \"title\": \" \\\\+\\\\ \", \"completed\": false }"
        let tokens = lexic(json)
        let container = try parse(tokens) as! Dictionary<String, Any?>
        XCTAssertEqual(container["userId"] as! Double, 1.0)
        XCTAssertEqual(container["id"] as! Double, 1.1)
        XCTAssertEqual(container["title"] as! String, " \\\\+\\\\ ")
        XCTAssertEqual(container["completed"] as! Bool, false)
    }

    func testPerformanceExample() {
        let json = "{ \"userId\": 1, \"id\": 1.1, \"title\": \" \\\\+\\\\ \", \"completed\": false }"
        measure {
            do {
                _ = try parse(lexic(json)) as! Dictionary<String, Any?>
            } catch {
                print(error)
            }
            
        }
    }

}

