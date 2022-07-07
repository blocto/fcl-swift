//
//  Error.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/14.
//

import Foundation

enum InternalError: Swift.Error {
    case callbackSelfNotfound
    case encodeToURLFailed
    case webSDKSessionFailed
}

public enum BloctoSDKError: Swift.Error {

    // info check
    case appIdNotSet

    // query
    case userRejected
    case forbiddenBlockchain
    case invalidResponse
    case userNotMatch

    // format check
    case ethSignInvalidHexString

    case other(code: String)

    init(code: String) {
        switch code {
        case Self.appIdNotSet.rawValue:
            self = .appIdNotSet
        case Self.userRejected.rawValue:
            self = .userRejected
        case Self.forbiddenBlockchain.rawValue:
            self = .forbiddenBlockchain
        case Self.invalidResponse.rawValue:
            self = .invalidResponse
        case Self.userNotMatch.rawValue:
            self = .userNotMatch
        case Self.ethSignInvalidHexString.rawValue:
            self = .ethSignInvalidHexString
        default:
            self = .other(code: code)
        }
    }

    var rawValue: String {
        switch self {
        case .appIdNotSet:
            return "app_id_not_set"
        case .userRejected:
            return "user_rejected"
        case .forbiddenBlockchain:
            return "forbidden_blockchain"
        case .invalidResponse:
            return "invalid_response"
        case .userNotMatch:
            return "user_not_match"
        case .ethSignInvalidHexString:
            return "eth_sign_invalid_hex_string"
        case .other(let code):
            return code
        }
    }

}
