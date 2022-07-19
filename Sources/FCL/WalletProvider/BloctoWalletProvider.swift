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

final class BloctoWalletProvider: WalletProvider {

    var bloctoFlowSDK: BloctoFlowSDK
    let providerInfo: ProviderInfo = ProviderInfo(
        title: "Blocto",
        desc: nil,
        icon: URL(string: "https://fcl-discovery.onflow.org/images/blocto.png")
    )
    let bloctoAppIdentifier: String

    /// Initial wallet provider
    /// - Parameters:
    ///   - bloctoAppIdentifier: identifier from app registered in blocto developer dashboard.
    ///        testnet dashboard: https://developers-staging.blocto.app/
    ///        mannet dashboard: https://developers.blocto.app/
    ///   - window: used for presenting webView if no Blocto app installed.
    ///   - testnet: indicate flow network to use.
    init(
        bloctoAppIdentifier: String,
        window: UIWindow?,
        testnet: Bool
    ) throws {
        self.bloctoAppIdentifier = bloctoAppIdentifier
        guard let window = window ?? Self.getKeyWindow() else {
            throw FCLError.walletProviderInitFailed
        }
        BloctoSDK.shared.initialize(
            with: bloctoAppIdentifier,
            window: window,
            logging: true,
            testnet: testnet
        )
        self.bloctoFlowSDK = BloctoSDK.shared.flow
    }

    /// Ask user to authanticate and get flow address along with account proof if provide accountProofData
    /// - Parameter accountProofData: AccountProofData used for proving a user controls an on-chain account, optional.
    func authn(accountProofData: FCLAccountProofData?) async throws {
        let (address, accountProof): (String, AccountProofSignatureData?) = try await withCheckedThrowingContinuation { continuation in
            var accountProofData: AccountProofData?
            if let fclAccountProofData = accountProofData {
                accountProofData = AccountProofData(
                    appId: fclAccountProofData.appId,
                    nonce: fclAccountProofData.nonce
                )
            }
            bloctoFlowSDK.authanticate(accountProofData: accountProofData) { result in
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
                            address: address,
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

    func authz() async throws -> String {
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
//        BloctoSDK.
        return ""
    }

    func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature] {
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
        return []
    }

    func preAuthz() async throws {
        guard let user = fcl.currentUser else { throw FCLError.userNotFound }
    }

//    func openId() async throws -> JSON {}

    func backChannelRPC() async throws {}

    private static func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter(\.isKeyWindow).first
    }

    private func topViewController(from window: UIWindow) -> UIViewController? {
        var topController: UIViewController? = nil
        while let presentedViewController = window.rootViewController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }

}
