//
//  Singature.swift
//  FCL-SDK
//
//  Created by Andrew Wang on 2022/8/16.
//

import Foundation

struct Singature: Encodable {
    let address: String
    let keyId: UInt32
    let sig: String?
}
