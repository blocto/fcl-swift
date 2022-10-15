//
//  WalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import FlowSDK
import Cadence

public protocol WalletProvider {
    
    /// Info to describe wallet provider
    var providerInfo: ProviderInfo { get }

    /// Method called by user changing network of Flow blockchain.
    /// - Parameter network: Flow network
    func updateNetwork(_ network: Network) throws
    
    /// Authentication of Flow blockchain account address. if valid account proof data provided,
    /// - Parameter accountProofData: Pre-defined struct used to sign for account proot.
    func authn(accountProofData: FCLAccountProofData?) async throws
    
    /// To retrive user signatures of specific input message.
    /// - Parameter message: A human readable string e.g. "message to be sign"
    /// - Returns: Pre-defined signature array.
    func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature]
    
    /// Modify Flow blockchain state with transaction compositions.
    /// - Parameters:
    ///   - cadence: Transaction script of Flow transaction.
    ///   - arguments: Arguments of Flow transaction.
    ///   - limit: Gas limit (compute limit) of Flow transaction.
    ///   - authorizers: Addresses of accounts data being modify by current transaction.
    /// - Returns: Transaction identifier (tx hash).
    func mutate(
        cadence: String,
        arguments: [Cadence.Argument],
        limit: UInt64,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier
    
    /// Retrive preSignable info  for Flow transaction.
    /// - Parameter preSignable: Pre-defined type.
    /// - Returns: Data includes proposer, payer, authorization.
    /// Only be used if wallet provider implement web send transaction.
    func preAuthz(preSignable: PreSignable?) async throws -> AuthData
    
    /// Method to modify url request before sending. Default implementation will not modify request.
    /// - Parameter request: URLRequest about to send.
    /// - Returns: URLRequest that has been modified.
    func modifyRequest(_ request: URLRequest) -> URLRequest

    /// Entry of Universal Links
    /// - Parameter userActivity: the same userActivity from UIApplicationDelegate
    /// Only be used if wallet provider involve other native app authentication.
    func continueForLinks(_ userActivity: NSUserActivity)

    /// Entry of custom scheme
    /// - Parameters:
    ///   - url: custom scheme URL
    /// Only be used if wallet provider involve other native app authentication.
    func application(open url: URL)

    // TODO: implementation
    /*
     func openId() async throws -> JSON {}
     */
}

extension WalletProvider {

    func modifyRequest(_ request: URLRequest) -> URLRequest {
        request
    }

    public func continueForLinks(_ userActivity: NSUserActivity) {}

    public func application(open url: URL) {}

}
