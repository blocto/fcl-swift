//
//  FCL.swift
//
//
//  Created by Andrew Wang on 2022/6/24.
//

import Foundation
import SDK
import Cadence

let fcl: FCL = FCL()

public class FCL {

    let config = Config()

    var user: User?

    init() {}

    public func config(
        provider: WalletProvider
    ) {}

    public func getAccount(address: String) async throws -> Account {}

    public func getLastestBlock() async throws -> Block {}

    public func login() async throws -> Address {}

    public func logout() {
        user = nil
    }
    
    public func relogin() async throws -> Address {
        logout()
        return await login()
    }
    
    // authz
    public func authorization()

    public func signUserMessage(message: String) async throws -> String {}
    
    public func query<QueryResult: Decodable>(script: String) async throws -> QueryResult {}

    public func sendTransaction(SDK.Transaction) async throws -> String {}
    
    public func getCustodialFeePayerAddress() async throws -> Address {}
    
    // MARK: Internal
    
    // authn
    func authanticate() async throws -> Address {
        
    }
    
    func serviceOfType(services: [Service], type: ServiceType) -> Service? {
        services?.first(where: { service in
            service.type == type
        })
    }

}

public enum RoutingMethod {
    case polling(accessNodeApi: URL)
    case native
}

public protocol WalletProvider {

    var routingMethod: RoutingMethod { get }

    init(routingMethod: RoutingMethod)

}
