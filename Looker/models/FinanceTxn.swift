//
//  FinanceTxn.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData

enum TxnInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case annually
}

enum TxnType: String, Codable, CaseIterable {
    case checking
    case savings
    case cash
    case credit
    case other
}

@Model
final class Txn: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var date: Date
    var desc: String
    var interval: TxnInterval
    var txnType: TxnType
    var expense: Bool
    
    init(
        id: UUID = UUID(),
        amount: Double,
        date: Date = Date(),
        desc: String,
        expense: Bool = false,
        _ interval: TxnInterval = .none,
        _ txnType: TxnType = .other
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.desc = desc
        self.expense = expense
        self.interval = interval
        self.txnType = txnType
    }
}
