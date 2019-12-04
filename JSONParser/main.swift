//
//  main.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-11-27.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

let json = "{ \"parser\": [\"yes\", true, 100, false] }"
print(json)

let characters = Array(json)

var tokens: Array<Any> = []
let numbers = "0123456789."

enum Capture {
    case tokens, string, t, f, number
}

var mod: Capture = .tokens

func captureToken(_ s: Character) -> Void {
    if s == "{" || s == "}" || s == "[" || s == "]" || s == "," || s == ":" {
        tokens.append(s)
    } else if s == "t" {
        tokens.append(String(s))
        mod = .t
    } else if s == "f" {
        tokens.append(String(s))
        mod = .f
    } else if numbers.contains(s) { // TODO: dot not double check first character
        tokens.append(String(s))
        mod = .number
    } else if s == "\"" { // TODO: dot not double check first character
        tokens.append("")
        mod = .string
    }
}

func captureString(_ s: Character) -> Bool {
    if s == "\"" {
        return true
    }
    var last = tokens.last as! String
    last.append(s)
    tokens[tokens.count-1] = last
    return false
}

func captureNumber(_ s: Character) -> Bool {
    var last = tokens.last as! String
    if numbers.contains(s) {
        last.append(s)
        tokens[tokens.count-1] = last
        return false
    }
    tokens[tokens.count-1] = Int(last)!
    return true
}

func captureBoolean(_ s: Character) throws -> Bool {
    var last = tokens.last as! String
    last.append(s)
    let check = mod == .t ? String(true) : String(false)
    if last.count == check.count {
        if check != last {
            throw NSError(domain: "Error parsing boolean value", code: 004)
        }
        tokens[tokens.count-1] = mod == .t
        return true
    }
    tokens[tokens.count-1] = last
    return false
}

do {
    for s in characters {
        switch mod {
        case .tokens:
            captureToken(s)
        case .string:
            if captureString(s) {
                mod = .tokens
            }
        case .number:
            if captureNumber(s) {
                captureToken(s)
                mod = .tokens
            }
        case .t, .f:
            if try captureBoolean(s) {
                mod = .tokens
            }
        }
    }
} catch let error as NSError {
    print(error)
}

print(tokens)

