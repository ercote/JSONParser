//
//  main.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-11-27.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

func lexic(_ json: String) -> Array<Any> {
    let characters = Array(json)

    var tokens: Array<Any> = []
    let numbers = "0123456789."

    enum Capture {
        case tokens, string, t, f, number, null
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
        } else if s == "n" {
            tokens.append(String(s))
            mod = .null
        } else if numbers.contains(s) {
            tokens.append(String(s))
            mod = .number
        } else if s == "\"" {
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
        tokens[tokens.count-1] = Double(last)!
        return true
    }

    func captureBoolean(_ s: Character) throws -> Bool {
        var last = tokens.last as! String
        last.append(s)
        let check = mod == .t ? String(true) : String(false)
        if last.count == check.count {
            if check != last {
                throw NSError(domain: "Error parsing value", code: 004)
            }
            tokens[tokens.count-1] = mod == .t
            return true
        }
        tokens[tokens.count-1] = last
        return false
    }

    func captureNull(_ s: Character) throws -> Bool {
        var last = tokens.last as! String
        last.append(s)
        if last.count == "null".count {
            if last != "null" {
                throw NSError(domain: "Error parsing value", code: 004)
            }
            tokens[tokens.count-1] = NSNull()
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
            case .null:
                if try captureNull(s) {
                    mod = .tokens
                }
            }
        }
    } catch let error as NSError {
        print(error)
    }

    return tokens
}

func parse(_ tokens: Array<Any>) throws -> Any? {
    enum Capture { case value, key, separator, keySeparator }

    var containers: Array<Any> = []

    var mod: Capture = .value
    var tmpKeys: [String] = []

    func assignValue(_ val: Any) {
        if let container = containers.last {
            if var arr = container as? Array<Any> {
                arr.append(val)
                containers[containers.count-1] = arr
            }
            if var obj = container as? Dictionary<String, Any> {
                obj[tmpKeys.popLast()!] = val
                containers[containers.count-1] = obj
            }
        } else {
            containers.append(val)
        }
        mod = .separator
    }

    for token in tokens {
        if let char = token as? Character {
            switch char {
            case "{":
                if mod != .value {
                    throw NSError(domain: "Unexpected value", code: 001)
                }
                mod = .key
                containers.append(Dictionary<String, Any>())
            case "}":
                if mod != .separator || !(containers.last is Dictionary<String, Any>) {
                    throw NSError(domain: "Unexpected value", code: 002)
                }
                assignValue(containers.popLast()!)
            case ",":
                if mod != .separator {
                    throw NSError(domain: "Unexpected value", code: 003)
                }
                mod = containers.last is Dictionary<String, Any> ? .key : .value
            case "[":
                if mod != .value {
                    throw NSError(domain: "Unexpected value", code: 004)
                }
                mod = .value
                containers.append(Array<Any>())
            case "]":
                if mod != .separator || !(containers.last is Array<Any>) {
                    throw NSError(domain: "Unexpected value", code: 005)
                }
                assignValue(containers.popLast()!)
            case ":":
                if mod != .keySeparator {
                    throw NSError(domain: "Unexpected value", code: 006)
                }
                mod = .value
            default:
                throw NSError(domain: "Unexpected value", code: 007)
            }
        } else if let str = token as? String {
            if mod == .key {
                tmpKeys.append(str)
                mod = .keySeparator
            } else if mod == .value {
                assignValue(str)
            } else {
                throw NSError(domain: "Unexpected value", code: 008)
            }
        } else {
            if mod != .value {
                throw NSError(domain: "Unexpected value", code: 009)
            }
            assignValue(token)
        }
    }
    return containers.first
}

let json = "{ \"userId\": 1, \"id\": 1.1, \"title\": \"+\", \"completed\": false }"
print("JSON:")
print(json)
let tokens = lexic(json)
print("LEXICAL:")
print(tokens)
print("PARSED:")
if let containers = try parse(tokens) {
    print(containers)
}
