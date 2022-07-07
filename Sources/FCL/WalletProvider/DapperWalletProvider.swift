//
//  DapperWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation

final class DapperWalletProvider: WalletProvider {

    static let `default`: DapperWalletProvider = {
        let info = ProviderInfo(
            title: "Dapper Wallet",
            desc: nil,
            icon: URL(string: "https://meetdapper.com/logos/logo_dapper_new.png")
        )
        return DapperWalletProvider(providerInfo: info)
    }

    var providerInfo: ProviderInfo
    var user: User?

    private var accessNodeApi: URL = URL(string: "https://dapper-http-post.vercel.app/api/authn")!
    
    init(providerInfo: ProviderInfo) {
        self.providerInfo = providerInfo
    }

    async func authn() throws {
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: accessNodeApi)
        let pollingResponse: PollingResponse = try await session.dataDecode(for: request)

        guard let localService = pollingResponse.local {
            throw FCLError.authenticateFailed
        }

        guard let updatesService = pollingResponse.updates {
            throw FCLError.authenticateFailed
        }

        try fcl.openWithWebAuthenticationSession(localService)
        let authnResponse = await fcl.polling(service: updatesService)

        user = try fcl.buildUser(authn: authnResponse)
    }

    async func authz() throws {
        guard let user = user else { throw FCLError.userNotFound }
        fcl.serviceOfType(services: user.services, type: .authz)
    }

    async func getUserSignature(_ signable: Signable) throws -> [Transaction.Signature] {
        guard let user = user else { throw FCLError.userNotFound }

    }

    async func preAuthz() throws {
        guard let user = user else { throw FCLError.userNotFound }

    }

    async func openId() throws

    async func backChannelRPC() throws
}
