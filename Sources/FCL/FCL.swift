//
//  FCL.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import FlowSDK
import Cadence
import AuthenticationServices

public let fcl: FCL = FCL()

func log(message: String) {
    print("FCL: " + message)
}

public class FCL: NSObject {

    public let config = Config()
    public var delegate: FCLDelegate?
    
    private var flowAPIClient: Client {
        Client(network: config.network)
    }

    private var webAuthSession: ASWebAuthenticationSession?
    private let requestSession = URLSession(configuration: .default)

    var currentUser: User?

    override init() {
        super.init()
        
    }

    public func config(
        provider: WalletProvider
    ) {}

    public func getAccount(address: String) async throws -> Account {
        throw FCLError.responseUnexpected
    }

    public func getLastestBlock() async throws -> Block {
        throw FCLError.responseUnexpected
    }

    public func login() async throws -> Address {
        throw FCLError.responseUnexpected
    }

    public func logout() {
        currentUser = nil
    }

    public func relogin() async throws -> Address {
        logout()
        return try await login()
    }

    // authn
    public func authanticate(accountProofData: FCLAccountProofData?) async throws -> Address {
        guard let walletProvider = config.selectedWalletProvider else {
            throw FCLError.walletProviderNotSpecified
        }
        
        try await walletProvider.authn(accountProofData: accountProofData)
        guard let user = fcl.currentUser else {
            throw FCLError.userNotFound
        }
        return user.address
    }
    
    public func unauthenticate() {
        fcl.currentUser = nil
    }
    
    public func reauthenticate(accountProofData: FCLAccountProofData?) async throws -> Address {
        unauthenticate()
        return try await authanticate(accountProofData: accountProofData)
    }

    // authz
    public func authorization() {}

    public func signUserMessage(message: String) async throws -> [FCLCompositeSignature] {
        // TODO: incomplete
        if let serviceType = try serviceOfType(type: .userSignature) {
            let request = try serviceType.getRequest()
            
        } else {
            try await fcl.config.selectedWalletProvider?.getUserSignature(message) ?? []
        }
        return []
    }

    public func query(
        script: String,
        arguments: [Value]
    ) async throws -> Value {
        let result = try flowAPIClient.executeScriptAtLatestBlock(
            script: Data(script.utf8),
            arguments: arguments
        ).wait()
        return result
    }

    public func sendTransaction(_ transaction: Transaction) async throws -> String {
        ""
    }

    public func getCustodialFeePayerAddress() async throws -> Address {
        throw FCLError.responseUnexpected
    }

    // MARK: Internal

    func serviceOfType(type: ServiceType) throws -> Service? {
        guard let currentUser = currentUser else {
            throw FCLError.userNotFound
        }
        return currentUser.services.first(where: { $0.type == type })
    }

    func openWithWebAuthenticationSession(_ service: Service) throws {
        let request = try service.getRequest()

        guard let url = request.url else {
            throw FCLError.urlNotFound
        }
        
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil,
            completionHandler: { _, _ in }
        )

        session.presentationContextProvider = self

        webAuthSession = session

        let startsSuccessfully = session.start()
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
            return try await polling(service: service)
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
            accountProof: nil,
            loggedIn: true,
            expiresAt: 0,
            services: authn.data?.services ?? []
        )
    }

}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension FCL: ASWebAuthenticationPresentationContextProviding {

    public func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        delegate?.webAuthenticationContextProvider() ?? ASPresentationAnchor()
    }

}
