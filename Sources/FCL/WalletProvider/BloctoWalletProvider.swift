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

final class BloctoWalletProvider: WalletProvider {
    
    static let `default`: BloctoWalletProvider = {
        let providerInfo = ProviderInfo(
            title: "Blocto",
            desc: nil,
            icon: URL(string: "https://fcl-discovery.onflow.org/images/blocto.png"))
        return BloctoWalletProvider(providerInfo: providerInfo)
    }()
    
    let providerInfo: ProviderInfo
    var user: User?
    
    init(providerInfo: ProviderInfo) {
        self.providerInfo = providerInfo
    }
    
    func authn() async throws {
        // Blocto SDK
//        let address = BloctoSDK.shared.flow.
//        user = User(
//            address: Address(hexString: address),
//            expiresAt: 0,
//            services: [])
//        user?.loggedIn = true
    }
    
    func authz() async throws -> String {
        guard let user = user else { throw FCLError.userNotFound }
//        BloctoSDK.
        return ""
    }
    
    func getUserSignature(_ message: String) async throws -> [CompositeSignature] {
        guard let user = user else { throw FCLError.userNotFound }
        return []
    }
    
    func preAuthz() async throws {
        guard let user = user else { throw FCLError.userNotFound }
    }
    
//    func openId() async throws -> JSON {}
    
    func backChannelRPC() async throws {}
    
}
