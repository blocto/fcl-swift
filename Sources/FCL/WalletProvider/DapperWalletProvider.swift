//
//  DapperWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import FlowSDK
import Cadence

final class DapperWalletProvider: WalletProvider {

    static let `default`: DapperWalletProvider = {
        let info = ProviderInfo(
            title: "Dapper Wallet",
            desc: nil,
            icon: URL(string: "https://meetdapper.com/logos/logo_dapper_new.png")
        )
        return DapperWalletProvider(providerInfo: info)
    }()

    var providerInfo: ProviderInfo
    var user: User?

    private var accessNodeApi: URL = URL(string: "https://dapper-http-post.vercel.app/api/authn")!

    init(providerInfo: ProviderInfo) {
        self.providerInfo = providerInfo
    }

    func authn(accountProofData: FCLAccountProofData?) async throws {
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: accessNodeApi)
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

        try fcl.openWithWebAuthenticationSession(localService)
        let authnResponse = try await fcl.polling(service: updatesService)
        fcl.currentUser = try fcl.buildUser(authn: authnResponse)
    }

    func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature] {
        throw FCLError.internal
    }
    
    func mutate(
        cadence: String,
        arguments: [Cadence.Argument],
        limit: UInt64,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier {
        throw FCLError.internal
    }
    
    func preAuthz(preSignable: PreSignable?) async throws -> AuthData {
        throw FCLError.internal
    }

}
