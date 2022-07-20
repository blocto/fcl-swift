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

    func getRequest() throws -> URLRequest {
        switch type {
        case .authn:
            throw FCLError.userNotFound
        case .authz:
            throw FCLError.userNotFound
        case .preAuthz:
            throw FCLError.userNotFound
        case .userSignature:
            guard let endpoint = endpoint else {
                throw FCLError.serviceError
            }
            var request = URLRequest(url: endpoint)
            request.httpMethod = method?.httpMethod
            let newRequest = try ParameterEncoding.encode(
                urlRequest: request,
                parameters: params,
                type: .jsonEncoding
            )
            return newRequest
        case .backChannel:
            guard let endpoint = endpoint,
                  var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
                throw FCLError.authenticateFailed
            }
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            guard let url = components.url else {
                throw FCLError.urlNotFound
            }
            return URLRequest(url: url)
        case .openId:
            throw FCLError.userNotFound
        case .accountProof:
            throw FCLError.userNotFound
        case .authnRefresh:
            throw FCLError.userNotFound
        }
    }

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
