//
//  AddressReplacement.swift
//  FCL
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import Cadence

struct AddressReplacement: Hashable {
    
    let placeholder: String
    let replacement: Address
    
    public init(
        placeholder: String,
        replacement: Address
    ) {
        self.placeholder = placeholder
        self.replacement = replacement
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(placeholder)
    }
}
