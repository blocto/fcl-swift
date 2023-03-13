//
//  PollingResponse.swift
//
//
//  Created by Andrew Wang on 2022/7/1.
//

import Foundation

/// Used for authn, authz and pre-authz
public struct AuthResponse: Codable {
    let fclType: String?
    let fclVersion: String?
    let status: ResponseStatus
    var updates: Service? // authn
    var local: Service? // authn, authz
    var data: AuthData?
    let reason: String?
    let compositeSignature: AuthData? // authz
    let authorizationUpdates: Service? // authz
    let userSignatures: [FCLCompositeSignature]

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case status
        case updates
        case local
        case data
        case reason
        case compositeSignature
        case authorizationUpdates
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try? container.decode(String.self, forKey: .fclType)
        self.fclVersion = try? container.decode(String.self, forKey: .fclVersion)
        self.status = try container.decode(ResponseStatus.self, forKey: .status)
        self.updates = try? container.decode(Service.self, forKey: .updates)
        do {
            self.local = try container.decode(Service.self, forKey: .local)
        } catch {
            let locals = try? container.decode([Service].self, forKey: .local)
            self.local = locals?.first
        }
        self.data = try? container.decode(AuthData.self, forKey: .data)
        self.userSignatures = (try? container.decode([FCLCompositeSignature].self, forKey: .data)) ?? []
        self.reason = try? container.decode(String.self, forKey: .reason)
        self.compositeSignature = try? container.decode(AuthData.self, forKey: .compositeSignature)
        self.authorizationUpdates = try? container.decode(Service.self, forKey: .authorizationUpdates)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fclType)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encode(status.rawValue, forKey: .status)
        try container.encodeIfPresent(reason, forKey: .reason)

        if userSignatures.isEmpty == false {
            try container.encode(userSignatures, forKey: .authorizationUpdates)
        }

        try container.encodeIfPresent(data, forKey: .data)
        // not support update for now
        /*
         try container.encodeIfPresent(updates, forKey: .updates)
         try container.encodeIfPresent(updates, forKey: .local)
         try container.encodeIfPresent(compositeSignature, forKey: .compositeSignature)
         try container.encodeIfPresent(authorizationUpdates, forKey: .authorizationUpdates)
          */
    }

    public init(
        fclType: String? = nil,
        fclVersion: String? = nil,
        status: ResponseStatus,
        updates: Service? = nil,
        local: Service? = nil,
        data: AuthData? = nil,
        reason: String? = nil,
        compositeSignature: AuthData? = nil,
        authorizationUpdates: Service? = nil,
        userSignatures: [FCLCompositeSignature] = []
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.status = status
        self.updates = updates
        self.local = local
        self.data = data
        self.reason = reason
        self.compositeSignature = compositeSignature
        self.authorizationUpdates = authorizationUpdates
        self.userSignatures = userSignatures
    }

    public static func initForSignMessageResponse(
        type: String = "PollingResponse",
        vsn: String = "1.0.0",
        status: ResponseStatus,
        userSignatures: [FCLCompositeSignature]
    ) -> AuthResponse {
        AuthResponse(
            fclType: type,
            fclVersion: vsn,
            status: status,
            userSignatures: userSignatures
        )
    }
}

/// Used for post pre-authz response
struct PollingWrappedResponse<Model: Decodable>: Decodable {
    let fclType: String?
    let fclVersion: String?
    let status: ResponseStatus
    let data: Model?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case status
        case data
        case reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try? container.decode(String.self, forKey: .fclType)
        self.fclVersion = try? container.decode(String.self, forKey: .fclVersion)
        self.status = try container.decode(ResponseStatus.self, forKey: .status)
        switch status {
        case .pending:
            self.reason = nil
            self.data = nil
        case .approved:
            self.reason = nil
            self.data = try container.decode(Model.self, forKey: .data)
        case .declined:
            self.reason = try? container.decode(String.self, forKey: .reason)
            self.data = nil
        }
    }
}
