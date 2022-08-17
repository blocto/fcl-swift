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

    var providerInfo: ProviderInfo { get }

    func authn(accountProofData: FCLAccountProofData?) async throws

    func getUserSignature(_ message: String) async throws -> [FCLCompositeSignature]

    func mutate(
        cadence: String,
        arguments: [Cadence.Argument],
        limit: UInt64,
        authorizers: [Cadence.Address]
    ) async throws -> Identifier

    func preAuthz(preSignable: PreSignable?) async throws -> AuthData

    // TODO: implementation
    /*
     func openId() async throws -> JSON {}
     */
}
