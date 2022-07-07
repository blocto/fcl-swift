//
//  WalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation

public protocol WalletProvider {

    var providerInfo: ProviderInfo { get }
    var user: User? { get }

    init(providerInfo: ProviderInfo)

    func authn() async throws

    func authz() async throws -> String

    func getUserSignature(_ message: String) async throws -> [CompositeSignature]

    func preAuthz() async throws

//    func openId() async throws

    func backChannelRPC() async throws

}
