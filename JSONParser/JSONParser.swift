//
//  JSONParser.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-12-15.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

public class JSONParser {
    
    func lexical(_ json: String) -> Array<Any> {
        let characters = Array(json)
        
        var tokens: Array<Any> = []
        let numbers = "0123456789."
        var capture: String = ""
        var isCaptureEscaped = false
        let escapableCharacters = "bfnrt\"\\"
        
        enum Capture {
            case tokens, string, t, f, number, null
        }
        
        var mod: Capture = .tokens
        
        func captureToken(_ s: Character) -> Void {
            if s == "{" || s == "}" || s == "[" || s == "]" || s == "," || s == ":" {
                tokens.append(s)
            } else if s == "t" {
                capture = String(s)
                mod = .t
            } else if s == "f" {
                capture = String(s)
                mod = .f
            } else if s == "n" {
                capture = String(s)
                mod = .null
            } else if numbers.contains(s) {
                capture = String(s)
                mod = .number
            } else if s == "\"" {
                capture = ""
                mod = .string
            }
        }
        
        func assignCapture(_ token: Any) -> Bool {
            tokens.append(token)
            capture = ""
            isCaptureEscaped = false
            return true
        }
        
        func captureString(_ s: Character) throws -> Bool {
            if s == "\""  {
                if isCaptureEscaped {
                    _ = capture.popLast()
                } else {
                    return assignCapture(capture)
                }
            } else if isCaptureEscaped, !escapableCharacters.contains(s) {
                throw NSError(domain: "Error escaped character", code: 001)
            }
            capture.append(s)
            isCaptureEscaped = s == "\\" && !isCaptureEscaped
            return false
        }
        
        func captureNumber(_ s: Character) -> Bool {
            if !numbers.contains(s) {
                return assignCapture(Double(capture)!)
            }
            capture.append(s)
            return false
        }
        
        func captureBoolean(_ s: Character) throws -> Bool {
            capture.append(s)
            let check = mod == .t ? String(true) : String(false)
            if capture.count == check.count {
                if check != capture {
                    throw NSError(domain: "Error parsing value", code: 004)
                }
                return assignCapture(mod == .t)
            }
            return false
        }
        
        func captureNull(_ s: Character) throws -> Bool {
            capture.append(s)
            if capture.count == "null".count {
                if capture != "null" {
                    throw NSError(domain: "Error parsing value", code: 004)
                }
                return assignCapture(NSNull())
            }
            return false
        }
        
        do {
            for s in characters {
                switch mod {
                case .tokens:
                    captureToken(s)
                case .string:
                    if try captureString(s) {
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
    
    func parseTokens(_ tokens: Array<Any>) throws -> Any? {
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
    
    private init() {
    }
    
    public static func parse(_ json: String) throws -> Any? {
        let parser = JSONParser()
        let tokens = parser.lexical(json)
        return try parser.parseTokens(tokens)
    }
}
