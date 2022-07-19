//
//  Config.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import FlowSDK

public enum WalletSelection {
    case authn(URL)
    case discoveryWallets([WalletProvider])
}

public class Config {

    var network: Network = .emulator

    var appDetail: AppDetail?

    var walletProviderCandidates: [WalletProvider] = []

    var selectedWalletProvider: WalletProvider?

    var addressReplacements: Set<AddressReplacement> = []

    public enum Option {
        @available(*, unavailable, renamed: "network", message: "Use network instead.")
        case env(String)
        case network(Network)

        case appDetail(AppDetail)

        @available(*, unavailable, renamed: "wallets", message: "Use supportedWalletProviders instead.")
        case challengeHandshake
        // Wallet Discovery mechanism
        case supportedWalletProviders([WalletProvider])

        case addressReplacement(AddressReplacement)

        // User info
//        case challengeScope
//        case openId
    }

    public func put(_ option: Option) -> Self {
        switch option {
        case let .network(network):
            self.network = network
        case .env:
            break
        case let .appDetail(appDetail):
            self.appDetail = appDetail
        case .challengeHandshake:
            break
        case let .supportedWalletProviders(walletProviders):
            walletProviderCandidates = walletProviders
            if walletProviders.count == 1,
               let firstProvider = walletProviders.first {
                selectedWalletProvider = firstProvider
            }
        case let .addressReplacement(replacement):
            addressReplacements.insert(replacement)
        }
        return self
    }

}
