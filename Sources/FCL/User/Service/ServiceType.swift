//
//  ServiceType.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public enum ServiceType: String, Decodable {
    case authn
    case authz
    case preAuthz = "pre-authz"
    case userSignature = "user-signature"
    case backChannel = "back-channel-rpc"
    case openId = "open-id"
    case accountProof = "account-proof"
    case authnRefresh = "authn-refresh"
    case localView = "local-view"
}

extension ServiceType: Equatable {}
