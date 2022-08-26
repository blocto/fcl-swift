//
//  PollingResponse.swift
//
//
//  Created by Andrew Wang on 2022/7/1.
//

import Foundation

/// Used for authn, authz and pre-authz
struct AuthResponse: Decodable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fclType = try? container.decode(String.self, forKey: .fclType)
        fclVersion = try? container.decode(String.self, forKey: .fclVersion)
        status = try container.decode(ResponseStatus.self, forKey: .status)
        updates = try? container.decode(Service.self, forKey: .updates)
        do {
            local = try container.decode(Service.self, forKey: .local)
        } catch {
            let locals = try? container.decode([Service].self, forKey: .local)
            local = locals?.first
        }
        data = try? container.decode(AuthData.self, forKey: .data)
        userSignatures = (try? container.decode([FCLCompositeSignature].self, forKey: .data)) ?? []
        reason = try? container.decode(String.self, forKey: .reason)
        compositeSignature = try? container.decode(AuthData.self, forKey: .compositeSignature)
        authorizationUpdates = try? container.decode(Service.self, forKey: .authorizationUpdates)
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
