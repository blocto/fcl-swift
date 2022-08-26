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
    case walletProviderNotSpecified
    case walletProviderInitFailed
    case responseUnexpected
    case authnFailed(message: String)
    case currentNetworkNotSupported
    case unexpectedResult
    case serviceError
    case invalidRequest
    case compositeSignatureInvalid
    case invaildProposer
    case fetchAccountFailure
    case missingPayer
    case unauthenticated
    case encodeFailed
    case userCanceled
    case serviceNotImplemented
    case unsupported

    case userNotFound
    case presentableNotFound
    case urlNotFound
    case serviceNotFound
    case resolverNotFound
    case accountNotFound
    case preAuthzNotFound
    case scriptNotFound
    case valueNotFound
    case authDataNotFound
    case latestBlockNotFound
    case keyNotFound
    case serviceTypeNotFound
}
