//
//  Service.swift
//  FCL
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation
import SwiftyJSON
import UIKit

public struct Service: Decodable {
    let fclType: String?
    let fclVersion: String?
    let type: ServiceType?
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
        self.fclType = try? container.decode(String.self, forKey: .fclType)
        self.fclVersion = try? container.decode(String.self, forKey: .fclVersion)
        self.type = try? container.decode(ServiceType.self, forKey: .type)
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
            guard let endpoint = endpoint else {
                throw FCLError.serviceError
            }
            guard let requestURL = buildURL(url: endpoint, params: params) else {
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
