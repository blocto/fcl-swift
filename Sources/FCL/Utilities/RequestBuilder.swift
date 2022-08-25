//
//  RequestBuilder.swift
//  FCL
//
//  Created by Andrew Wang on 2022/8/12.
//

import Foundation

enum RequstBuilder {

    static func buildURLRequest(
        url: URL,
        method: ServiceMethod?,
        body: [String: Any] = [:]
    ) throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method?.httpMethod

        guard let selectedWalletProvider = fcl.config.selectedWalletProvider else {
            throw FCLError.walletProviderNotSpecified
        }
        
        var newRequest = selectedWalletProvider.modifyRequest(urlRequest)

        if newRequest.httpMethod == ServiceMethod.httpPost.httpMethod {
            var object = body
            if let appDetail = fcl.config.appDetail {
                let appDetailDic = try appDetail.toDictionary()
                object = object.merging(appDetailDic, uniquingKeysWith: { $1 })
            }
            if fcl.config.openIdScopes.isEmpty == false {
                let openIdScopesDic = try fcl.config.openIdScopes.toDictionary()
                object = object.merging(openIdScopesDic, uniquingKeysWith: { $1 })
            }
            let clientInfoDic = try ClientInfo().toDictionary()
            object = object.merging(clientInfoDic, uniquingKeysWith: { $1 })
            let body = try? JSONSerialization.data(withJSONObject: object)
            newRequest.httpBody = body
            newRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            newRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        return newRequest
    }

}
