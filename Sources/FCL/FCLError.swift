//
//  FCLError.swift
//  
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation

public enum FCLError: Swift.Error {
    case `internal`
    case parameterEncodingFailed
    case authenticateFailed
    case userNotFound
    case walletProviderNotSpecified
    case walletProviderInitFailed
    case presentableNotFound
    case responseUnexpected
    case urlNotFound
    case authnFailed(message: String)
    case currentNetworkNotSupported
    case unexpectedResult
    case serviceError
    case invalidRequest
    case compositeSignatureInvalid
    case invaildProposer
    case fetchAccountFailure
    case resolverNotFound
    case missingPayer
    case accountNotFound
    case unauthenticated
    case preAuthzNotFound
    case encodeFailed
    case scriptNotFound
    case valueNotFound
}
