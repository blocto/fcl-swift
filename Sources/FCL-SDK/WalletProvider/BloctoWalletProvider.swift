//
//  BloctoWalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import UIKit
import FlowSDK
import BloctoSDK
import SwiftyJSON
import Cadence

public final class BloctoWalletProvider: WalletProvider {

    var bloctoFlowSDK: BloctoFlowSDK
    public let providerInfo: ProviderInfo = ProviderInfo(
        title: "Blocto",
        desc: "Entrance to blockchain world.",
        icon: URL(string: "https://ipfs.blocto.app/ipfs/QmTmQQBz5KfVUcHW83S3kxqh29vSQ3cH7pcsc6cngYsG5U")
    )
    private(set) var network: Network
    private(set) var environment: BloctoEnvironment

    private let bloctoAppIdentifier: String

    private var bloctoAppScheme: String {
        switch environment {
        case .prod:
            return "blocto://"
        case .dev:
            return "blocto-dev://"
        }
    }

    private var bloctoApiBaseURLString: String {
        switch environment {
        case .prod:
            return "https://api.blocto.app"
        case .dev:
            return "https://api-dev.blocto.app"
        }
    }

    private var webAuthnURL: URL? {
        switch environment {
        case .prod:
            return URL(string: "https://flow-wallet.blocto.app/api/flow/authn")
        case .dev:
            return URL(string: "https://flow-wallet-testnet.blocto.app/api/flow/authn")
        }
    }

    /// Initial wallet provider
    /// - Parameters:
    ///   - bloctoAppIdentifier: identifier from app registered in blocto developer dashboard.
    ///        testnet dashboard: https://developers-staging.blocto.app/
    ///        mainnet dashboard: https://developers.blocto.app/
    ///   - window: used for presenting webView if no Blocto app installed. If pass nil then we will get the top ViewContoller from keyWindow.
    ///   - network: indicate flow network to use.
    ///   - logging: Enabling log message, default is true.
    public init(
        bloctoAppIdentifier: String,
        window: UIWindow?,
        network: Network,
        logging: Bool = true
    ) throws {
        self.bloctoAppIdentifier = bloctoAppIdentifier
        let getWindow = { () throws -> UIWindow in
            guard let window = window ?? fcl.getKeyWindow() else {
                throw FCLError.walletProviderInitFailed
            }
            return window
        }
        self.network = network
        if let environment = Self.getBloctoEnvironment(by: network) {
            self.environment = environment
        } else {
            throw FCLError.currentNetworkNotSupported
        }
        BloctoSDK.shared.initialize(
            with: bloctoAppIdentifier,
            getWindow: getWindow,
            logging: logging,
            environment: environment
        )
        self.bloctoFlowSDK = BloctoSDK.shared.flow
    }

    /// Get called when config network changed
    /// - Parameter network: Flow network
    public func updateNetwork(_ network: Network) throws {
        self.network = network
        if let environment = Self.getBloctoEnvironment(by: network) {
            self.environment = environment
        } else {
            throw FCLError.currentNetworkNotSupported
        }
        BloctoSDK.shared.updateEnvironment(environment)
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

            let feePayer = try await bloctoFlowSDK.getFeePayerAddress()

            let transaction = try FlowSDK.Transaction(
                script: Data(cadence.utf8),
                arguments: arguments,
                referenceBlockId: block.blockHeader.id,
                gasLimit: limit,
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

    public func modifyRequest(_ request: URLRequest) -> URLRequest {
        var newRequest = request
        newRequest.addValue(bloctoAppIdentifier, forHTTPHeaderField: "Blocto-Application-Identifier")
        return newRequest
    }

    /// Entry of Universal Links
    /// - Parameter userActivity: the same userActivity from UIApplicationDelegate
    public func continueForLinks(_ userActivity: NSUserActivity) {
        BloctoSDK.shared.continue(userActivity)
    }

    /// Entry of custom scheme
    /// - Parameters:
    ///   - url: custom scheme URL
    public func application(open url: URL) {
        BloctoSDK.shared.application(open: url)
    }

    // MARK: - Private

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
                    continuation.resume(throwing: FCLError.authnFailed(message: String(describing: error)))
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

    private static func getBloctoEnvironment(by network: Network) -> BloctoEnvironment? {
        switch network {
        case .mainnet:
            return .prod
        case .testnet:
            return .dev
        case .canarynet:
            return nil
        case .sandboxnet:
            return nil
        case .emulator:
            return nil
        }
    }

}
