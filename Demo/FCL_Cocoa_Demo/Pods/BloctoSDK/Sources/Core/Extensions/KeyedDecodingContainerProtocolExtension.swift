//
//  KeyedDecodingContainerProtocolExtension.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/4/15.
//

import Foundation

public extension KeyedDecodingContainerProtocol {

    // MARK: - Dictionary
    func decodeStringDataDictionary(forKey key: Self.Key) throws -> [String: Data] {
        let stringDataDict = try decode([String: String].self, forKey: key)

        var result: [String: Data] = [:]
        for (string, hexString) in stringDataDict {
            guard let data = Data(hexString: hexString) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected hexadecimal string")
            }
            result[string] = data
        }

        return result
    }

}
