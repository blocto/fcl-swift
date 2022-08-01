//
//  Service.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation
import SwiftyJSON
import UIKit

public struct Service: Decodable {
    let fclType: String
    let fclVersion: String
    let type: ServiceType
    let method: ServiceMethod?
    let endpoint: URL?
    let uid: String?
    let id: String?
    let identity: ServiceIdentity?
    let provider: ServiceProvider?
    let params: [String: String]
    let data: ServiceDataType

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case type
        case method
        case endpoint
        case uid
        case id
        case identity
        case provider
        case params
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try container.decode(String.self, forKey: .fclType)
        self.fclVersion = try container.decode(String.self, forKey: .fclVersion)
        self.type = try container.decode(ServiceType.self, forKey: .type)
        self.method = try? container.decode(ServiceMethod.self, forKey: .method)
        self.endpoint = try? container.decode(URL.self, forKey: .endpoint)
        self.uid = try? container.decode(String.self, forKey: .uid)
        self.id = try? container.decode(String.self, forKey: .id)
        self.identity = try? container.decode(ServiceIdentity.self, forKey: .identity)
        self.provider = try? container.decode(ServiceProvider.self, forKey: .provider)
        self.params = (try? container.decode([String: String].self, forKey: .params)) ?? [:]
        switch type {
        case .openId:
            if let openId = try? container.decode(JSON.self, forKey: .data) {
                self.data = .openId(openId)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "open id data structure not exist."
                    )
                )
            }
        case .accountProof:
            if let accountProof = try? container.decode(ServiceAccountProof.self, forKey: .data) {
                self.data = .accountProof(accountProof)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "account proof data structure not valid or not exist."
                    )
                )
            }
        case .authn,
             .authz,
             .preAuthz,
             .backChannel,
             .userSignature,
             .authnRefresh:
            if let json = try? container.decode(JSON.self, forKey: .data) {
                self.data = .json(json)
            } else {
                self.data = .notExist
            }
        }
    }
}

extension Service {

    func getURLRequest(body: Data? = nil) throws -> URLRequest {
        switch type {
        case .authn:
            throw FCLError.userNotFound
        case .authz:
            throw FCLError.userNotFound
        case .preAuthz,
                .userSignature,
                .backChannel:
            guard let endpoint = endpoint else {
                throw FCLError.serviceError
            }
            guard let requestURL = buildURL(url: endpoint, params: params) else {
                throw FCLError.invalidRequest
            }
            let request = try buildURLRequest(url: requestURL, body: body)
            return request
        case .openId:
            throw FCLError.userNotFound
        case .accountProof:
            throw FCLError.userNotFound
        case .authnRefresh:
            throw FCLError.userNotFound
        }
    }

    private func buildURL(url: URL, params: [String: String] = [:]) -> URL? {
        let paramLocation = "l6n"
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var queryItems: [URLQueryItem] = []

        if let location = fcl.config.location?.value {
            queryItems.append(URLQueryItem(name: paramLocation, value: location))
        }

        for (name, value) in params {
            if name != paramLocation {
                queryItems.append(
                    URLQueryItem(name: name, value: value)
                )
            }
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
    }

    private func buildURLRequest(url: URL, body: Data? = nil) throws -> URLRequest {
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
            if let data = body {
                var object = try data.toDictionary()
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
            }
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

extension Encodable {
    /// Converting object to postable dictionary
    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Deserialized object is not a dictionary")
            throw DecodingError.typeMismatch(type(of: object), context)
        }
        return json
    }
}

extension Data {
    
    func toDictionary() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self)
        guard let json = object as? [String: Any] else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Deserialized data is not a dictionary")
            throw DecodingError.typeMismatch(type(of: object), context)
        }
        return json
    }
    
}
