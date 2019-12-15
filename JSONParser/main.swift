//
//  main.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-11-27.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

let json = "{ \"userId\": 1, \"id\": 1.1, \"title\": \" \\\\+\\\\ \", \"completed\": false }"
print("JSON:")
print(json)
let tokens = lexic(json)
print("LEXICAL:")
print(tokens)
print("PARSED:")
if let containers = try parse(tokens) {
    print(containers)
}
