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

        if let origin = fcl.config.location {
            switch origin {
            case let .domain(url):
                urlRequest.addValue(url.absoluteString, forHTTPHeaderField: "referer")
            case let .bloctoAppIdentifier(string):
                urlRequest.addValue(string, forHTTPHeaderField: "Blocto-Application-Identifier")
            }
        }
        urlRequest.httpMethod = method?.httpMethod
        switch method {
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
             .data,
             .none:
            break
        }
        return urlRequest
    }

}
