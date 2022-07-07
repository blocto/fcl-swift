//
//  DataExtensions.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/4/15.
//

import Foundation
import CommonCrypto

extension Data {

    public init?(hexString: String) {
        let string: String
        if hexString.hasPrefix("0x") {
            string = String(hexString.dropFirst(2))
        } else {
            string = hexString
        }

        // Check odd length hex string
        if string.count % 2 != 0 {
            return nil
        }

        // Convert the string to bytes for better performance
        guard let stringData = string.data(using: .ascii, allowLossyConversion: true) else {
            return nil
        }

        self.init(capacity: string.count / 2)
        let stringBytes = Array(stringData)
        for i in stride(from: 0, to: stringBytes.count, by: 2) {
            guard let high = Data.value(of: stringBytes[i]) else {
                return nil
            }
            if i < stringBytes.count - 1, let low = Data.value(of: stringBytes[i + 1]) {
                append((high << 4) | low)
            } else {
                append(high)
            }
        }
    }

    /// Converts an ASCII byte to a hex value.
    private static func value(of nibble: UInt8) -> UInt8? {
        guard let letter = String(bytes: [nibble], encoding: .ascii) else { return nil }
        return UInt8(letter, radix: 16)
    }

}

extension Data: BloctoSDKCompatible {}

extension BloctoSDKHelper where Base == Data {

    public var hexStringWith0xPrefix: String {
        "0x" + hexString
    }

    /// Returns the hex string representation of the data.
    public var hexString: String {
        return base.map({ String(format: "%02x", $0) }).joined()
    }

    public var sha256: Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        base.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return Data(hash)
    }

}
