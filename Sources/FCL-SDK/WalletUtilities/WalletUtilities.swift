//
//  WalletUtilities.swift
//  
//
//  Created by Andrew Wang on 2022/7/11.
//

import Foundation
import FlowSDK
import Cadence

public enum WalletUtilities {
    
    public static func encodeAccountProof(
        address: Address,
        nonce: String,
        appIdentifier: String,
        includeDomainTag: Bool
    ) -> String {
        let accountProofData: RLPEncodable = [
            appIdentifier,
            Data(hex: String(address.hexString)),
            Data(hex: nonce),
        ]
        if includeDomainTag {
            return (DomainTag.accountProof.rightPaddedData + accountProofData.rlpData).toHexString()
        } else {
            return accountProofData.rlpData.toHexString()
        }
    }
    
}
