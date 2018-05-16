//
//  ViewController.swift
//  Calculation
//
//  Created by はるふ on 2018/05/09.
//  Copyright © 2018年 はるふ. All rights reserved.
//

import UIKit

enum InfixOperator: String {
    case plus = "+"
    case minus = "-"
    case divide = "/"
    case multiply = "*"
    
    static let operators1 = "[\(InfixOperator.plus.regex)\(InfixOperator.minus.regex)]"
    static let operators2 = "[\(InfixOperator.multiply.regex)\(InfixOperator.divide.regex)]"
    
    var regex: String {
        switch self {
        case .plus:
            return "\\\(rawValue)"
        case .minus:
            return rawValue
        case .divide:
            return rawValue
        case .multiply:
            return "\\\(rawValue)"
        }
    }
    
    func calculate(_ lhs: Double, _ rhs: Double) -> Double {
        switch self {
        case .plus:
            return lhs + rhs
        case .minus:
            return lhs - rhs
        case .divide:
            return lhs / rhs
        case .multiply:
            return lhs * rhs
        }
    }
}

enum ExpressionError: Error {
    case invalidInput
    case failedParsingValue
    case unknown
}

indirect enum Expression {
    case value(Double)
    case statement(InfixOperator, Expression, Expression)
}

extension Expression {
    // MARK: calculating
    
    func calculateResult() -> Double {
        switch self {
        case .value(let value):
            return value
        case .statement(let op, let e1, let e2):
            return op.calculate(e1.calculateResult(), e2.calculateResult())
        }
    }
}

extension Expression {
    // MARK: parsing
    
    private static let floatPattern = "[0-9]+(?:\\.[0-9]+)?"
    private static let blockPattern = "[(\\[](.+)[)\\]]"
    private static let exp1Pattern = "(?:\(blockPattern)|(\(floatPattern)))"
    private static let exp2Pattern = "\(exp1Pattern)(?:([*/])\(exp1Pattern))*"
    private static let exp3Pattern = "\(exp2Pattern)(?:([\\+-])\(exp2Pattern))*"
    
    private static func _parse3(_ string: String) throws -> Expression {
        if try! Regex("^\(floatPattern)$").matches(string) {
            guard let value = Double(string) else {
                throw ExpressionError.failedParsingValue
            }
            return Expression.value(value)
        }
        
        if let match = try! Regex("^\(blockPattern)$").firstMatch(string) {
            // マッチした時点で必ずnot nil
            return try parse(match.groups[0]!)
        }
        
        // _parse2から呼ぶ限りはありえない
        throw ExpressionError.unknown
    }
    
    private static func _parse2(_ string: String) throws -> Expression {
        let exp1i = exp1Pattern.ignoringExtractions()
        let regex = try! Regex("^(\(exp1i))(?:(\(InfixOperator.operators2))(.+))?$")
        guard let match = regex.firstMatch(string) else {
            throw ExpressionError.unknown
        }
        let e1 = try _parse3(match.groups[0]!)
        
        guard let op = match.groups[1], let right = match.groups[2] else {
            return e1
        }
        let e2 = try _parse2(right)
        if let unwrappedOp = InfixOperator(rawValue: op) {
            return Expression.statement(unwrappedOp, e1, e2)
        }
        
        // 正規表現からありえない
        throw ExpressionError.unknown
    }
    
    static func parse(_ string: String) throws -> Expression {
        let exp2i = exp2Pattern.ignoringExtractions()
        let regex = try! Regex("^(\(exp2i))(?:(\(InfixOperator.operators1))(.+))?$")
        guard let match = regex.firstMatch(string) else {
            throw ExpressionError.invalidInput
        }
        let e1 = try _parse2(match.groups[0]!)
        
        guard let op = match.groups[1], let right = match.groups[2] else {
            return e1
        }
        
        let e2 = try parse(right)
        if let unwrappedOp = InfixOperator(rawValue: op) {
            return Expression.statement(unwrappedOp, e1, e2)
        }
        
        // 正規表現からありえない
        throw ExpressionError.unknown
    }
}


class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 13
        print(try! Expression.parse("(1+(1+2))*3+4-3").calculateResult())
    }
}

