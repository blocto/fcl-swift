//
//  Service.swift
//  FCL
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation
import SwiftyJSON
import UIKit

public struct Service: Codable {
    let fclType: String?
    let fclVersion: String?
    let type: ServiceType?
    let method: ServiceMethod?
    let endpoint: String?
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

    public init(
        fclType: String = "Service",
        fclVersion: String = "1.0.0",
        type: ServiceType,
        method: ServiceMethod,
        endpoint: String? = nil,
        uid: String? = nil,
        id: String? = nil,
        identity: ServiceIdentity? = nil,
        provider: ServiceProvider? = nil,
        params: [String: String] = [:],
        data: ServiceDataType = .notExist
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.type = type
        self.method = method
        self.endpoint = endpoint
        self.uid = uid
        self.id = id
        self.identity = identity
        self.provider = provider
        self.params = params
        self.data = data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try? container.decode(String.self, forKey: .fclType)
        self.fclVersion = try? container.decode(String.self, forKey: .fclVersion)
        self.type = try? container.decode(ServiceType.self, forKey: .type)
        self.method = try? container.decode(ServiceMethod.self, forKey: .method)
        self.endpoint = try? container.decode(String.self, forKey: .endpoint)
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
                self.data = .notExist
            }
        case .authn,
             .localView,
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
        case .none:
            self.data = .notExist
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(fclType, forKey: .fclType)
        try container.encodeIfPresent(fclVersion, forKey: .fclVersion)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(method, forKey: .method)
        try container.encodeIfPresent(endpoint, forKey: .endpoint)
        try container.encodeIfPresent(uid, forKey: .uid)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(identity, forKey: .identity)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encode(params, forKey: .params)
        switch data {
        case let .openId(json):
            try container.encode(json, forKey: .data)
        case let .accountProof(serviceAccountProof):
            try container.encode(serviceAccountProof, forKey: .data)
        case let .json(json):
            try container.encode(json, forKey: .data)
        case .notExist:
            break
        }
    }
}

extension Service {

    func getURLRequest(body: Data? = nil) throws -> URLRequest {
        switch type {
        case .authn:
            throw FCLError.serviceNotImplemented
        case .localView,
             .preAuthz,
             .userSignature,
             .backChannel,
             .authz,
             .none:
            guard let endpoint = endpoint,
                  let endpointURL = URL(string: endpoint) else {
                throw FCLError.serviceError
            }
            guard let requestURL = buildURL(url: endpointURL, params: params) else {
                throw FCLError.invalidRequest
            }
            let object = try body?.toDictionary() ?? [:]
            return try RequstBuilder.buildURLRequest(url: requestURL, method: method, body: object)
        case .openId:
            throw FCLError.serviceNotImplemented
        case .accountProof:
            throw FCLError.serviceNotImplemented
        case .authnRefresh:
            throw FCLError.serviceNotImplemented
        }
    }

    private func buildURL(url: URL, params: [String: String] = [:]) -> URL? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var queryItems: [URLQueryItem] = []

        for (name, value) in params {
            queryItems.append(
                URLQueryItem(name: name, value: value)
            )
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
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
