//
//  File.swift
//
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import Cadence

public struct User: Decodable {

    public var fclType: String = Pragma.user.fclType
    public var fclVersion: String = Pragma.user.fclVersion
    public let address: Address
    public var loggedIn: Bool = false
    public let expiresAt: TimeInterval
    private var accountProofData: AccountProofSignatureData?
    public let services: [Service]

    public var accountProof: AccountProofSignatureData? {
        if let proof = accountProofData {
            return proof.signatures.isEmpty ? nil : proof
        } else {
            do {
                let accountProofService = try fcl.serviceOfType(type: .accountProof)
                if case let .accountProof(serviceAccountProof) = accountProofService?.data {
                    return AccountProofSignatureData(
                        address: address,
                        nonce: serviceAccountProof.nonce,
                        signatures: serviceAccountProof.signatures)
                }
                return nil
            } catch {
                return nil
            }
        }
    }

    var expiresAtDate: Date {
        Date(timeIntervalSince1970: expiresAt)
    }

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case loggedIn
        case expiresAt
        case services
    }

    public init(
        fclType: String,
        fclVersion: String,
        address: Address,
        accountProof: AccountProofSignatureData?,
        loggedIn: Bool = false,
        expiresAt: TimeInterval,
        services: [Service]
    ) {
        self.fclType = fclType
        self.fclVersion = fclVersion
        self.address = address
        self.accountProofData = accountProof
        self.loggedIn = loggedIn
        self.expiresAt = expiresAt
        self.services = services
    }
    
    public init(
        address: Address,
        accountProof: AccountProofSignatureData?,
        loggedIn: Bool = false,
        expiresAt: TimeInterval,
        services: [Service]
    ) {
        self.address = address
        self.accountProofData = accountProof
        self.loggedIn = loggedIn
        self.expiresAt = expiresAt
        self.services = services
    }

}
