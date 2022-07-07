//
//  FCL.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import SDK
import Cadence
import AuthenticationServices

let fcl: FCL = FCL()

public class FCL {

    public let config = Config()
    public var delegate: FCLDelegate?

    private var webAuthSession: ASWebAuthenticationSession?
    private let requestSession = URLSession(configuration: .default)

    var user: User?

    init() {}

    public func config(
        provider: WalletProvider
    ) {}

    public func getAccount(address: String) async throws -> Account {}

    public func getLastestBlock() async throws -> Block {}

    public func login() async throws -> Address {}

    public func logout() {
        user = nil
    }

    public func relogin() async throws -> Address {
        logout()
        return await login()
    }

    // authz
    public func authorization()

    public func signUserMessage(message: String) async throws -> String {}

    public func query<QueryResult: Decodable>(script: String) async throws -> QueryResult {}

    public func sendTransaction(SDK.Transaction) async throws -> String {}

    public func getCustodialFeePayerAddress() async throws -> Address {}

    // authn
    public func authanticate(_ presentable: Presentable? = nil) async throws -> Address {
        guard let walletProvider = config.selectedWalletProvider else {
            throw FCLError.walletProviderNotSpecified
        }

        await walletProvider.authn()
        guard let user = walletProvider.user else {
            throw FCLError.userNotFound
        }
        return user.address
    }

    // MARK: Internal

    func serviceOfType(services: [Service], type: ServiceType) -> Service? {
        services?.first(where: { $0.type == type })
    }

    func openWithWebAuthenticationSession(_ service: Service) throws {
        let request = try service.getRequest()

        let session = ASWebAuthenticationSession(
            url: request.url,
            callbackURLScheme: nil,
            completionHandler: { _, _ }
        )

        guard let delegate = delegate else {
            throw FCLError.presentableNotFound
        }

        session.presentationContextProvider = self

        webAuthSession = session

        let startsSuccessfully = session?.start()
        if startsSuccessfully == false {
            throw FCLError.authenticateFailed
        }
    }

    func polling(service: Service) async throws -> AuthnResponse {
        let request = try service.getRequest()
        let authnResponse: AuthnResponse = try await requestSession.dataDecode(for: request)
        switch authnResponse.status {
        case .pending:
            try await Task.sleep(seconds: 1)
            return await polling(service: service)
        case .approved, .declined:
            webAuthSession?.cancel()
            webAuthSession = nil
            return authnResponse
        }
    }

    func buildUser(authn: AuthnResponse) throws -> User {
        guard let address = authn.data?.address else {
            throw FCLError.authenticateFailed
        }
        return User(
            address: Address(hexString: address),
            loggedIn: true,
            expiresAt: 0,
            services: authn.data?.services ?? []
        )
    }

}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension FCL: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        delegate?.webAuthenticationContextProvider() ?? ASPresentationAnchor()
    }

}
