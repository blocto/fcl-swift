//
//  Service.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation
import SwiftyJSON

struct Service: Decodable {
    let fclType: String
    let fclVersion: String
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
        case fclType = "fType"
        case fclVersion = "fVsn"
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try? container.decode(String.self, forKey: .fType)
        self.fclVersion = try? container.decode(String.self, forKey: .fVsn)
        self.type = try? container.decode(ServiceType.self, forKey: .type)
        self.method = try? container.decode(ServiceMethod.self, forKey: .method)
        self.endpoint = try? container.decode(URL.self, forKey: .endpoint)
        self.uid = try? container.decode(String.self, forKey: .uid)
        self.id = try? container.decode(String.self, forKey: .id)
        self.identity = try? container.decode(ServiceIdentity.self, forKey: .identity)
        self.provider = try? container.decode(ServiceProvider.self, forKey: .provider)
        self.params = try? container.decode(JSON.self, forKey: .params) ?? [:]
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
             .localView,
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
