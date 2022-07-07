//
//  BloctoWalletProvider.swift
//  
//
//  Created by Andrew Wang on 2022/7/5.
//

import Foundation
import SDK
import BloctoSDK
import SwiftyJSON

final class BloctoWalletProvider: WalletProvider {
    
    static let `default`: BloctoWalletProvider = {
        let providerInfo = ProviderInfo(
            title: "Blocto",
            desc: nil,
            icon: URL(string: "https://fcl-discovery.onflow.org/images/blocto.png"))
        return BloctoWalletProvider(providerInfo: providerInfo)
    }
    
    var providerInfo: ProviderInfo
    var user: User?
    
    init(providerInfo: ProviderInfo) {
        self.providerInfo = providerInfo
    }
    
    async func authn() throws {
        // Blocto SDK
        let address = BloctoSDK.requestAccount()
        user = User(
            address: Address(hexString: address),
            expiresAt: 0,
            services: [])
        user?.loggedIn = true
    }
    
    async func authz() throws {
        guard let user = user else { throw FCLError.userNotFound }
//        BloctoSDK.
    }
    
    async func getUserSignature(_ signable: Signable) throws -> [Transaction.Signature] {
        guard let user = user else { throw FCLError.userNotFound }

    }
    
    async func preAuthz() throws {
        guard let user = user else { throw FCLError.userNotFound }
    }
    
    async func openId() throws -> JSON
    
    async func backChannelRPC() throws
    
}
