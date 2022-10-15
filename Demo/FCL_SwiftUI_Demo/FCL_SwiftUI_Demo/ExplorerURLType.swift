//
//  ExplorerURLType.swift
//  FCL_SwiftUI_Demo
//
//  Created by Andrew Wang on 2022/9/7.
//

import Foundation
import FlowSDK

enum ExplorerURLType {
    case txHash(String)
    case address(String)

    func url(network: Network) -> URL? {
        switch self {
        case let .txHash(hash):
            return network == .mainnet
                ? URL(string: "https://flowscan.org/transaction/\(hash)")
                : URL(string: "https://testnet.flowscan.org/transaction/\(hash)")
        case let .address(address):
            return network == .mainnet
                ? URL(string: "https://flowscan.org/account/\(address)")
                : URL(string: "https://testnet.flowscan.org/account/\(address)")
        }
    }
}
