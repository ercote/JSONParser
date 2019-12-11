//
//  main.swift
//  JSONParser
//
//  Created by Eric Cote on 2019-11-27.
//  Copyright © 2019 Eric Cote. All rights reserved.
//

import Foundation

let json = "{ \"parser\": [\"yes\", true, 100, false] }"

func lexic(_ json: String) -> Array<Any> {
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
    
    return tokens
}

class Container {
    var parent: Container?
    var nodes: [Container] = []
    private(set) var obj: Any
    init(withObj obj: Array<Any>) {
        self.obj = obj
    }
    init(withObj obj: Dictionary<String, Any>) {
        self.obj = obj
    }
    public func addValue(_ val: Any) {
        var arr = obj as! Array<Any>
        arr.append(val)
    }
    public func addValue(value val: Any, forKey key: String) {
        var dict = obj as! Dictionary<String, Any>
        dict[key] = val
    }
    func addContainer(_ container: Container) {
        container.parent = self
        self.nodes.append(container)
    }
    public func addListContainer() -> Container {
        let newContainer = Container(withObj: [])
        addContainer(newContainer)
        return newContainer
    }
    public func addObjectContainer() -> Container {
        let newContainer = Container(withObj: Dictionary())
        addContainer(newContainer)
        return newContainer
    }
}

func parse(_ tokens: Array<Any>) throws -> Container {
    enum Capture { case value, key, separator, keySeparator }

    var container: Container = Container(withObj: [])
    
    var mod: Capture = .value
    var tmpKeys: [String] = []
    
    func assignValue(_ val: Any) {
        if container.obj is Array<Any> {
            container.addValue(val)
        } else if let key = tmpKeys.last {
            container.addValue(value: val, forKey: key)
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
                container = container.addObjectContainer()
            case "}":
                if mod != .separator || !(container.obj is Dictionary<String, Any>) {
                    throw NSError(domain: "Unexpected value", code: 002)
                }
                mod = .separator
                container = container.parent!
            case ",":
                if mod != .separator {
                    throw NSError(domain: "Unexpected value", code: 003)
                }
                mod = .value
            case "[":
                if mod != .value {
                    throw NSError(domain: "Unexpected value", code: 004)
                }
                container = container.addListContainer()
            case "]":
                if mod != .separator || !(container.obj is Array<Any>) {
                    throw NSError(domain: "Unexpected value", code: 005)
                }
                mod = .separator
                container = container.parent!
            case ":":
                if mod != .keySeparator {
                    throw NSError(domain: "Unexpected value", code: 006)
                }
                mod = .value
            default:
                throw NSError(domain: "Unexpected value", code: 007)
            }
        } else if let str = token as? String {
            if mod != .value && mod != .key {
                throw NSError(domain: "Unexpected value", code: 008)
            }
            if mod == .key {
                tmpKeys.append(str)
                mod = .keySeparator
            } else if mod == .value {
                assignValue(str)
            }
        } else if token is Double || token is Bool {
            if mod != .value {
                throw NSError(domain: "Unexpected value", code: 009)
            }
            assignValue(token)
        }
    }
    while let parent = container.parent {
        container = parent
    }
    return container
}

let tokens = lexic(json)
let container = try parse(tokens)

print(tokens)
print(container.obj)
