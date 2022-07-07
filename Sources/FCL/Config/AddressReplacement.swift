//
//  AddressReplacement.swift
//  
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation

public struct AddressReplacement: Hashable {
    
    let placeholder: String
    let replacement: String
    
    public init(
        placeholder: String,
        replacement: String
    ) {
        self.placeholder = placeholder
        self.replacement = replacement
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(placeholder)
    }
}
