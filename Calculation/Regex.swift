//
//  Regex.swift
//  ha1fRegex
//
//  Created by はるふ on 2016/09/30.
//  Copyright © 2016年 はるふ. All rights reserved.
//

import Foundation

struct Regex {
    static let PATTERN_FLOAT = "-*([1-9]\\d*|0)(\\.\\d+)?"
    static let PATTERN_EMAIL = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)+$"
    
    static let email = try! Regex(PATTERN_EMAIL)
    static let float = try! Regex(PATTERN_FLOAT)
    
    struct Match {
        var wholeString = ""
        var groups = [String?]()
        
        init(wholeString: String, groups: [String]) {
            self.wholeString = wholeString
            self.groups = groups
        }
        
        init(text: NSString, result res: NSTextCheckingResult) {
            let components = (0..<res.numberOfRanges)
                .map { i -> String? in
                    let range = res.range(at: i)
                    guard range.location != NSNotFound else {
                        // ない可能性のある()だとnilのこともある
                        return nil
                    }
                    return text.substring(with: res.range(at: i))
            }
            self.wholeString = components.first.flatMap { $0 } ?? ""
            self.groups = components.dropFirst().map { $0 }
        }
    }
    
    fileprivate let regex: NSRegularExpression
    
    init(_ pattern: String, options: NSRegularExpression.Options = []) throws {
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: options)
        }
    }
    
    func matches(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return self.firstMatch(string, range: range, options: options) != nil
    }
    
    func firstMatch(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> Match? {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        if let res = self.regex.firstMatch(in: string, options: options, range: targetRange) {
            return Regex.Match(text: nsstring, result: res)
        } else {
            return nil
        }
    }
    
    func allMatches(_ string: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> [Match] {
        let targetRange = range ?? string.wholeNSRange()
        let nsstring = string as NSString
        return self.regex.matches(in: string, options: options, range: targetRange).map { res in
            return Regex.Match(text: nsstring, result: res)
        }
    }
}

extension String {
    fileprivate func wholeRange() -> Range<String.Index> {
        return self.startIndex..<self.endIndex
    }
    
    fileprivate func wholeNSRange() -> NSRange {
        return NSRange(location: 0, length: self.count)
    }
    
    func replace(_ regex: Regex, with template: String, range: NSRange? = nil, options: NSRegularExpression.MatchingOptions = []) -> String {
        let targetRange = range ?? self.wholeNSRange()
        return regex.regex.stringByReplacingMatches(in: self, options: options, range: targetRange, withTemplate: template)
    }
    
    /// (を(?:で置換する
    func ignoringExtractions() -> String {
        return replace(try! Regex("\\((?!\\?:)"), with: "(?:")
    }
}
