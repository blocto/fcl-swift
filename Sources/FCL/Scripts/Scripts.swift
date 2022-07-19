//
//  Scripts.swift
//
//
//  Created by Andrew Wang on 2022/7/15.
//

import Foundation
import Cadence

public enum Scripts {

    static func verifyAccountProof(
        contractAddress: Address,
        verifyFunction: String
    ) -> String {
        """
        import FCLCrypto from \(contractAddress.hexString)

        pub fun main(
            address: Address,
            message: String,
            keyIndices: [Int],
            signatures: [String]
        ): Bool {
            return FCLCrypto.\(verifyFunction)(
                address: address,
                message: message,
                keyIndices: keyIndices,
                signatures: signatures)
        }
        """
    }

}
