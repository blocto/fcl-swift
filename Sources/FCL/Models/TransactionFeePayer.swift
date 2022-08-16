//
//  TransactionFeePayer.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/29.
//

import Foundation
import Cadence

/// The key that specifies the fee payer address with key for a transaction.
public struct TransactionFeePayer: Equatable {

    public let address: Address
    public let keyIndex: Int
    
    public var tempId: String {
        address.hexString + "-" + String(keyIndex)
    }

    public init(address: Address, keyIndex: Int) {
        self.address = address
        self.keyIndex = keyIndex
    }

}
