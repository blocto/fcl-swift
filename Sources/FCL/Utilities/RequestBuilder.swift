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

        if let bloctoWalletProvider = fcl.config.selectedWalletProvider as? BloctoWalletProvider {
            urlRequest.addValue(bloctoWalletProvider.bloctoAppIdentifier, forHTTPHeaderField: "Blocto-Application-Identifier")
        }
        var adjustMethod = method

        /// Workaround
        if fcl.config.selectedWalletProvider is DapperWalletProvider,
           url.absoluteString.contains("https://dapper-http-post.vercel.app/api/authn-poll") {
            /// Though POST https://dapper-http-post.vercel.app/api/authn?l6n=https://foo.com response back-channel-rpc using method HTTP/POST
            /// Requesting using GET will only be accepted by dapper wallet.
            adjustMethod = .httpGet
        }
        urlRequest.httpMethod = adjustMethod?.httpMethod
        switch adjustMethod {
        case .httpPost:
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
            urlRequest.httpBody = body
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        case .httpGet,
             .iframe,
             .iframeRPC,
             .browserIframe,
             .data,
             .none:
            break
        }
        return urlRequest
    }

}
