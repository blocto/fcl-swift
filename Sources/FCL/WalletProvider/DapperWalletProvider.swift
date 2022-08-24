//
//  DapperWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import FlowSDK
import Cadence

public final class DapperWalletProvider: WalletProvider {

    public static let `default`: DapperWalletProvider = {
        let info = ProviderInfo(
            title: "Dapper Wallet",
            desc: nil,
            icon: URL(string: "https://i.imgur.com/L1dgOKn.png")
        )
        return DapperWalletProvider(providerInfo: info)
    }()

    public var providerInfo: ProviderInfo
    var user: User?

    // mainnet only for now
    private var accessNodeApiString: String {
        switch fcl.config.network {
        case .testnet:
            return ""
        case .mainnet:
            return "https://dapper-http-post.vercel.app/api/authn"
        case .canarynet,
                .emulator:
            return ""
        }
    }

    init(providerInfo: ProviderInfo) {
        self.providerInfo = providerInfo
    }

    public func authn(accountProofData: FCLAccountProofData?) async throws {
        let session = URLSession(configuration: .default)
        let urlComponent = URLComponents(string: accessNodeApiString)
        guard let requestURL = urlComponent?.url else {
            throw FCLError.urlNotFound
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"

        let pollingResponse = try await session.dataAuthnResponse(for: request)

        guard let localService = pollingResponse.local else {
            throw FCLError.authenticateFailed
        }

        guard let updatesService = pollingResponse.updates else {
            throw FCLError.authenticateFailed
        }

        if accountProofData != nil {
            log(message: "Dapper not support native account proof for now.")
        }

        let openBrowserTask = Task { @MainActor in
            try fcl.openWithWebAuthenticationSession(localService)
            let authnResponse = try await fcl.polling(service: updatesService)
            fcl.currentUser = try fcl.buildUser(authn: authnResponse)
        }
        _ = try await openBrowserTask.result.get()
    }

    public func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature] {
        throw FCLError.unsupported
    }

    public func mutate(
        cadence: String,
        arguments: [Cadence.Argument],
        limit: UInt64,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier {
        throw FCLError.unsupported
    }

    public func preAuthz(preSignable: PreSignable?) async throws -> AuthData {
        throw FCLError.unsupported
    }

}
