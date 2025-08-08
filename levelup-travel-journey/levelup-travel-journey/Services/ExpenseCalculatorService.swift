//  ExpenseCalculatorService.swift
//  My Travel
//
//  Simple helper to convert from another currency to THB given user-provided FX rate.

import Foundation

enum ExpenseCalculatorService {
    // amount in foreign currency * rateToTHB = THB
    static func convertToTHB(amount: Decimal, rateToTHB: Decimal) -> Decimal {
        // (a * r)
        let nsAmount = NSDecimalNumber(decimal: amount)
        let nsRate = NSDecimalNumber(decimal: rateToTHB)
        return nsAmount.multiplying(by: nsRate).decimalValue
    }
}
