//
//  StringExtensions.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/4/18.
//

import Foundation

extension String: BloctoSDKCompatible {}

extension BloctoSDKHelper where Base == String {

    public var drop0x: String {
        if base.hasPrefix("0x") {
            return String(base.dropFirst(2))
        }
        return base
    }

    public var add0x: String {
        if base.hasPrefix("0x") {
            return base
        }
        return "0x" + base
    }

    public var hexDecodedData: Data {
        // Convert to a CString and make sure it has an even number of characters (terminating 0 is included, so we
        // check for uneven!)
        guard let cString = base.cString(using: .ascii), (cString.count % 2) == 1 else {
            return Data()
        }

        var result = Data(capacity: (cString.count - 1) / 2)
        for i in stride(from: 0, to: (cString.count - 1), by: 2) {
            guard let l = hexCharToByte(cString[i]), let r = hexCharToByte(cString[i+1]) else {
                return Data()
            }
            var value: UInt8 = (l << 4) | r
            result.append(&value, count: MemoryLayout.size(ofValue: value))
        }
        return result
    }

    public func hexConvertToString() -> String {
        if base.prefix(2) == "0x" {
            return String(
                data: String(base.dropFirst(2)).bloctoSDK.hexDecodedData,
                encoding: .utf8) ?? base
        } else {
            return base
        }
    }

    private func hexCharToByte(_ c: CChar) -> UInt8? {
        if c >= 48 && c <= 57 { // 0 - 9
            return UInt8(c - 48)
        }
        if c >= 97 && c <= 102 { // a - f
            return UInt8(10) + UInt8(c - 97)
        }
        if c >= 65 && c <= 70 { // A - F
            return UInt8(10) + UInt8(c - 65)
        }
        return nil
    }

}
