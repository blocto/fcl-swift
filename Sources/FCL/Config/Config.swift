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

public enum Origin {
    /// Used for web to identify where request comes from
    case domain(URL)

    ///  Get from blocto developer dashboard
    ///     - testnet dashboard: https://developers-staging.blocto.app/
    ///     - mannet dashboard: https://developers.blocto.app/
    ///  It will be automatically set if selectedWalletProvider set to BloctoWalletProvider
    case bloctoAppIdentifier(String)

    var value: String {
        switch self {
        case let .domain(url):
            return url.absoluteString
        case let .bloctoAppIdentifier(bloctoAppId):
            return bloctoAppId
        }
    }
}

public enum Scope: String, Encodable {
    case email
    case name
}

public class Config {

    var network: Network = .emulator

    var appDetail: AppDetail?

    var walletProviderCandidates: [WalletProvider] = []

    var selectedWalletProvider: WalletProvider? {
        didSet {
            if let provider = selectedWalletProvider as? BloctoWalletProvider {
                put(
                    .location(
                        .bloctoAppIdentifier(provider.bloctoAppIdentifier)
                    )
                )
            }
        }
    }

    var addressReplacements: Set<AddressReplacement> = []
    
    /// To Identify where service request comes from.
    var location: Origin?
    
    var computeLimit: UInt64 = defaultComputeLimit
    
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

        case location(Origin)

        case computeLimit(UInt64)

        // User info
        /* TODO: implementation
        case challengeScope "challenge.scope"
        case openId([Scope])
        */
    }

    @discardableResult
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
        case let .replace(placeholder, replacement):
            let addressReplacement = AddressReplacement(placeholder: placeholder, replacement: replacement)
            addressReplacements.insert(addressReplacement)
        case let .location(origin):
            location = origin
        case let .computeLimit(limit):
            computeLimit = limit
        /* TODO: implementation
        case let .openId(scopes):
            openIdScopes = scopes
        */
        }
        return self
    }

}
