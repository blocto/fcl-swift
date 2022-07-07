//
//  WalletProvider.swift
//
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import Cadence

public protocol WalletProvider {

    var providerInfo: ProviderInfo
    var user: User?

    init(providerInfo: ProviderInfo)

    async func authn() throws

    async func authz() -> String throws

    async func getUserSignature(hexString: String) throws -> [CompositeSignature]

    async func preAuthz() throws

    async func openId() throws

    async func backChannelRPC() throws

}
