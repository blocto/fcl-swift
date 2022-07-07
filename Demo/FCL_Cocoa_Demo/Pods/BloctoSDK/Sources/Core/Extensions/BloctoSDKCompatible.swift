//
//  BloctoSDKCompatible.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/5/26.
//

import Foundation

public protocol BloctoSDKCompatible {
    associatedtype someType
    var bloctoSDK: someType { get }
}

public extension BloctoSDKCompatible {
    var bloctoSDK: BloctoSDKHelper<Self> {
        get { return BloctoSDKHelper(self) }
    }
}

public struct BloctoSDKHelper<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}
