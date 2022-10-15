//
//  Config.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import FlowSDK
import Cadence

public enum WalletSelection {
    case authn(URL)
    case discoveryWallets([WalletProvider])
}

public enum Scope: String, Encodable {
    case email
    case name
}

public class Config {

    var network: Network = .testnet

    var appDetail: AppDetail?

    var walletProviderCandidates: [WalletProvider] = []

    var selectedWalletProvider: WalletProvider?

    var addressReplacements: Set<AddressReplacement> = []
    
    var computeLimit: UInt64 = defaultComputeLimit
    
    /// To switch on and off for logging message
    var logging: Bool = true
    
    var openIdScopes: [Scope] = []

    public enum Option {
        @available(*, unavailable, renamed: "network", message: "Use network instead.")
        case env(String)
        case network(Network)

        case appDetail(AppDetail)

        @available(*, unavailable, renamed: "wallets", message: "Use supportedWalletProviders instead.")
        case challengeHandshake
        // Wallet Discovery mechanism
        case supportedWalletProviders([WalletProvider])

        case replace(placeHolder: String, with: Address)

        case computeLimit(UInt64)
        
        case logging(Bool)

        // User info
        /* TODO: implementation
        case challengeScope "challenge.scope"
        case openId([Scope])
        */
    }

    @discardableResult
    public func put(_ option: Option) throws -> Self {
        switch option {
        case let .network(network):
            self.network = network
            try walletProviderCandidates.forEach {
                try $0.updateNetwork(network)
            }
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
            try walletProviderCandidates.forEach {
                try $0.updateNetwork(network)
            }
        case let .replace(placeholder, replacement):
            let addressReplacement = AddressReplacement(placeholder: placeholder, replacement: replacement)
            addressReplacements.insert(addressReplacement)
        case let .computeLimit(limit):
            computeLimit = limit
        case let .logging(enable):
            logging = enable
        /* TODO: implementation
        case let .openId(scopes):
            openIdScopes = scopes
        */
        }
        return self
    }
    
    public func reset() {
        selectedWalletProvider = nil
    }

}
