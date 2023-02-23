//
//  DynamicKey.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2023/2/23.
//

import Foundation

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        fatalError("init(intValue:) has not been implemented")
    }

}
