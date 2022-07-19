//
//  AppUtilities.swift
//
//
//  Created by Andrew Wang on 2022/7/11.
//

import Foundation
import Cadence
import BigInt
import FlowSDK

public enum AppUtilities {

    public static func accountProofContractAddress(
        network: Network
    ) throws -> Address {
        switch network {
        case .mainnet:
            return Address(hexString: "0xb4b82a1c9d21d284")
        case .testnet:
            return Address(hexString: "0x74daa6f9c7ef24b1")
        case .canarynet,
             .emulator:
            throw FCLError.currentNetworkNotSupported
        }
    }

    public static func getVerifySignaturesScript(
        isAccountProof: Bool,
        fclCryptoContract: Address?
    ) throws -> String {
        let contractAddress: Address
        if let fclCryptoContract = fclCryptoContract {
            contractAddress = fclCryptoContract
        } else {
            contractAddress = try accountProofContractAddress(network: fcl.config.network)
        }

        let verifyFunction = isAccountProof
            ? "verifyAccountProofSignatures"
            : "verifyUserSignatures"

        return """
        import FCLCrypto from \(contractAddress.hexString)

        pub fun main(
            address: Address,
            message: String,
            keyIndices: [Int],
            signatures: [String]
        ): Bool {
            return FCLCrypto.\(verifyFunction)(
                address: address,
                message: message,
                keyIndices: keyIndices,
                signatures: signatures)
        }
        """
    }

    public static func verifyAccountProof(
        appIdentifier: String,
        accountProofData: AccountProofSignatureData,
        fclCryptoContract: Address?
    ) async throws -> Bool {
        let verifyMessage = WalletUtilities.encodeAccountProof(
            address: accountProofData.address,
            nonce: accountProofData.nonce,
            appIdentifier: appIdentifier,
            includeDomainTag: false
        )

        var indices: [Value] = []
        var siganature: [Value] = []
        for signature in accountProofData.signatures {
            indices.append(.int(BigInt(signature.keyId)))
            siganature.append(.string(signature.signature))
        }

        // Arrange
        guard let user = fcl.currentUser else {
            throw FCLError.userNotFound
        }
        let arguments: [Cadence.Value] = [
            .address(user.address),
            .string(verifyMessage),
            .array(indices),
            .array(siganature),
        ]

        // Act
        let verifyScript = try getVerifySignaturesScript(
            isAccountProof: true,
            fclCryptoContract: fclCryptoContract
        )
        let result = try await fcl.query(
            script: verifyScript,
            arguments: arguments)
        guard case let .bool(valid) = result else {
            throw FCLError.unexpectedResult
        }
        return valid
    }

}
