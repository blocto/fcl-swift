//
//  BloctoWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import FlowSDK
import BloctoSDK
import SwiftyJSON
import Cadence

public final class BloctoWalletProvider: WalletProvider {

    var bloctoFlowSDK: BloctoFlowSDK
    public let providerInfo: ProviderInfo = ProviderInfo(
        title: "Blocto",
        desc: nil,
        icon: URL(string: "https://fcl-discovery.onflow.org/images/blocto.png")
    )
    let bloctoAppIdentifier: String
    let isTestnet: Bool

    private var bloctoAppScheme: String {
        if isTestnet {
            return "blocto-staging://"
        } else {
            return "blocto://"
        }
    }

    private var bloctoApiBaseURLString: String {
        if isTestnet {
            return "https://api-staging.blocto.app"
        } else {
            return "https://api.blocto.app"
        }
    }

    private var webAuthnURL: URL? {
        if isTestnet {
            return URL(string: "https://flow-wallet-testnet.blocto.app/api/flow/authn")
        } else {
            return URL(string: "https://flow-wallet.blocto.app/api/flow/authn")
        }
    }

    /// Initial wallet provider
    /// - Parameters:
    ///   - bloctoAppIdentifier: identifier from app registered in blocto developer dashboard.
    ///        testnet dashboard: https://developers-staging.blocto.app/
    ///        mannet dashboard: https://developers.blocto.app/
    ///   - window: used for presenting webView if no Blocto app installed. If pass nil then we will get the top ViewContoller from keyWindow.
    ///   - testnet: indicate flow network to use.
    public init(
        bloctoAppIdentifier: String,
        window: UIWindow?,
        testnet: Bool
    ) throws {
        self.bloctoAppIdentifier = bloctoAppIdentifier
        let getWindow = { () throws -> UIWindow in
            guard let window = window ?? Self.getKeyWindow() else {
                throw FCLError.walletProviderInitFailed
            }
            return window
        }
        self.isTestnet = testnet
        BloctoSDK.shared.initialize(
            with: bloctoAppIdentifier,
            getWindow: getWindow,
            logging: true,
            testnet: testnet
        )
        self.bloctoFlowSDK = BloctoSDK.shared.flow
    }

    /// Ask user to authanticate and get flow address along with account proof if provide accountProofData
    /// - Parameter accountProofData: AccountProofData used for proving a user controls an on-chain account, optional.
    public func authn(accountProofData: FCLAccountProofData?) async throws {
        if let bloctoAppSchemeURL = URL(string: bloctoAppScheme),
           await UIApplication.shared.canOpenURL(bloctoAppSchemeURL) {
            // blocto app installed
            try await setupUserByBloctoSDK(accountProofData)
        } else {
            // blocto app not install
            guard let authnURL = webAuthnURL else {
                throw FCLError.urlNotFound
            }
            var data: [String: String] = [:]
            if let accountProofData = accountProofData {
                data["accountProofIdentifier"] = accountProofData.appId
                data["accountProofNonce"] = accountProofData.nonce
            }

            let authnRequest = try RequstBuilder.buildURLRequest(
                url: authnURL,
                method: .httpPost,
                body: data
            )
            let authResponse = try await fcl.pollingRequest(authnRequest, type: .authn)
            fcl.currentUser = try fcl.buildUser(authn: authResponse)
        }
    }

    public func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature] {
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
        if let bloctoAppSchemeURL = URL(string: bloctoAppScheme),
           await UIApplication.shared.canOpenURL(bloctoAppSchemeURL) {
            // blocto app installed
            return try await withCheckedThrowingContinuation { continuation in
                bloctoFlowSDK.signMessage(
                    from: user.address.hexStringWithPrefix,
                    message: message
                ) { result in
                    switch result {
                    case let .success(flowCompositeSignatures):
                        continuation.resume(returning: flowCompositeSignatures.map {
                            FCLCompositeSignature(
                                address: $0.address,
                                keyId: $0.keyId,
                                signature: $0.signature
                            )
                        })
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } else {
            // blocto app not install
            guard let userSignatureService = try fcl.serviceOfType(type: .userSignature) else {
                throw FCLError.serviceNotFound
            }

            let encoder = JSONEncoder()
            let encodeData = try encoder.encode(["message": Data(message.utf8).toHexString()])
            let response = try await fcl.polling(
                service: userSignatureService,
                data: encodeData
            )
            return response.userSignatures
        }
    }

    public func mutate(
        cadence: String,
        arguments: [Cadence.Argument],
        limit: UInt64,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier {
        if let bloctoAppSchemeURL = URL(string: bloctoAppScheme),
           await UIApplication.shared.canOpenURL(bloctoAppSchemeURL) {

            guard let userAddress = fcl.currentUser?.address else {
                throw FCLError.userNotFound
            }
            guard let account = try await fcl.flowAPIClient.getAccountAtLatestBlock(address: userAddress) else {
                throw FCLError.accountNotFound
            }
            guard let block = try await fcl.flowAPIClient.getLatestBlock(isSealed: true) else {
                throw FCLError.latestBlockNotFound
            }

            guard let cosignerKey = account.keys
                .first(where: { $0.weight == 999 && $0.revoked == false }) else {
                throw FCLError.keyNotFound
            }

            let proposalKey = Transaction.ProposalKey(
                address: userAddress,
                keyIndex: cosignerKey.index,
                sequenceNumber: cosignerKey.sequenceNumber
            )
            
            let feePayer = try await bloctoFlowSDK.getFeePayerAddress(isTestnet: isTestnet)

            let transaction = try FlowSDK.Transaction(
                script: Data(cadence.utf8),
                arguments: arguments,
                referenceBlockId: block.blockHeader.id,
                proposalKey: proposalKey,
                payer: feePayer,
                authorizers: authorizers
            )
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                guard let self = self else {
                    continuation.resume(throwing: FCLError.internal)
                    return
                }
                Task { @MainActor in
                    self.bloctoFlowSDK.sendTransaction(
                        from: userAddress,
                        transaction: transaction
                    ) { result in
                        switch result {
                        case let .success(txId):
                            continuation.resume(returning: Identifier(hexString: txId))
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } else {
            return try await fcl.send([
                .transaction(script: cadence),
                .computeLimit(limit),
                .arguments(arguments),
            ])
        }
    }

    /// Retrive preSignable info for Flow transaction
    /// - Parameter preSignable: Pre-defined type.
    /// - Returns: Data includes proposer, payer, authorization.
    /// Only used if Blocto native app not install.
    public func preAuthz(preSignable: PreSignable?) async throws -> AuthData {
        guard fcl.currentUser != nil else { throw FCLError.userNotFound }
        // blocto app not install
        guard let service = try fcl.serviceOfType(type: .preAuthz) else {
            throw FCLError.preAuthzNotFound
        }

        var data: Data?
        if let preSignable = preSignable {
            data = try JSONEncoder().encode(preSignable)
        }

        // for blocto pre-authz it will response approved directly once request.
        let authResponse = try await fcl.polling(service: service, data: data)
        guard let authData = authResponse.data else {
            throw FCLError.authDataNotFound
        }
        return authData
    }

    private static func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter(\.isKeyWindow).first
    }

    private func topViewController(from window: UIWindow) -> UIViewController? {
        var topController: UIViewController?
        while let presentedViewController = window.rootViewController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

    private func setupUserByBloctoSDK(_ accountProofData: FCLAccountProofData?) async throws {
        let (address, accountProof): (String, AccountProofSignatureData?) = try await withCheckedThrowingContinuation { continuation in
            var bloctoAccountProofData: FlowAccountProofData?
            if let accountProofData = accountProofData {
                bloctoAccountProofData = FlowAccountProofData(
                    appId: accountProofData.appId,
                    nonce: accountProofData.nonce
                )
            }
            bloctoFlowSDK.authanticate(accountProofData: bloctoAccountProofData) { result in
                switch result {
                case let .success((address, accountProof)):
                    if let fclAccountProofData = accountProofData {
                        let fclAccountProofSignatures = accountProof.map {
                            FCLCompositeSignature(
                                address: $0.address,
                                keyId: $0.keyId,
                                signature: $0.signature
                            )
                        }
                        let accountProofSignatureData = AccountProofSignatureData(
                            address: Address(hexString: address),
                            nonce: fclAccountProofData.nonce,
                            signatures: fclAccountProofSignatures
                        )
                        continuation.resume(returning: (address, accountProofSignatureData))
                    } else {
                        continuation.resume(returning: (address, nil))
                    }
                case let .failure(error):
                    continuation.resume(throwing: FCLError.authnFailed(message: error.localizedDescription))
                }
            }
        }

        fcl.currentUser = User(
            address: Address(hexString: address),
            accountProof: accountProof,
            loggedIn: true,
            expiresAt: 0,
            services: []
        )
    }

}
