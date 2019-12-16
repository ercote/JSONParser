//
//  main.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-11-27.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

// TODO: accept file patch or json inline as command line argument

let json = "{ \"userId\": 1, \"id\": 1.1, \"title\": \" \\\\+\\\\ \", \"completed\": false }"
if let containers = try JSONParser.parse(json) {
    print(containers)
}
