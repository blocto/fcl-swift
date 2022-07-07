//
//  Config.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation

public enum WalletSelection {
    case authn(URL)
    case discoveryWallets([WalletProvider])
}

public class Config {

    var env: ChainEnv = .emulator

    var appDetail: AppDetail?

    var walletProviderCandidates: [WalletProvider] = []

    var selectedWalletProvider: WalletProvider?

    var addressReplacements: Set<AddressReplacement> = []

    public enum Option {
        case env(ChainEnv)
        case appDetail(AppDetail)

        @available(*, unavailable, renamed: "wallets", message: "Use supportedWalletProviders instead.")
        case challengeHandshake
        // Wallet Discovery mechanism
        case supportedWalletProviders([WalletProvider])

        case addressReplacement(AddressReplacement)

        // User info
        case challengeScope
        case openId
    }

    func put(_ option: Option) -> Self {
        switch option {
        case let .env(env):
            self.env = env
        case let .appDetail(appDetail):
            self.appDetail = appDetail
        case .challengeHandshake:
            break
        case let .supportedWalletProvider(walletProviders):
            walletProviderCandidates = walletProviders
            if walletProviders.count == 1,
               let firstProvider = walletProviders.first {
                selectedWalletProvider = firstProvider
            } else if walletProviders.isEmpty {
                selectedWalletProvider = BloctoWalletProvider.default
            }
        case let .addressReplacement(replacement):
            addressReplacements.insert(replacement)
        }
        return self
    }

}
