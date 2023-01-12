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

    public static func verifyAccountProof(
        appIdentifier: String,
        accountProofData: AccountProofVerifiable,
        fclCryptoContract: Address?
    ) async throws -> Bool {
        let verifyMessage = WalletUtilities.encodeAccountProof(
            address: accountProofData.address,
            nonce: accountProofData.nonce,
            appIdentifier: appIdentifier,
            includeDomainTag: false
        )

        var indices: [Cadence.Argument] = []
        var siganature: [Cadence.Argument] = []
        for signature in accountProofData.signatures {
            indices.append(.int(BigInt(signature.keyId)))
            siganature.append(.string(signature.signature))
        }

        let arguments: [Cadence.Argument] = [
            .address(accountProofData.address),
            .string(verifyMessage),
            .array(indices),
            .array(siganature),
        ]

        let verifyScript = try getVerifySignaturesScript(
            isAccountProof: true,
            fclCryptoContract: fclCryptoContract
        )
        let result = try await fcl.query(
            script: verifyScript,
            arguments: arguments
        )
        guard case let .bool(valid) = result.value else {
            throw FCLError.unexpectedResult
        }
        return valid
    }

    public static func verifyUserSignatures(
        message: String,
        signatures: [CompositeSignatureVerifiable],
        fclCryptoContract: Address?
    ) async throws -> Bool {

        guard let address = signatures.first?.address else {
            throw FCLError.compositeSignatureInvalid
        }

        var indices: [Cadence.Argument] = []
        var siganature: [Cadence.Argument] = []
        for signature in signatures {
            indices.append(.int(BigInt(signature.keyId)))
            siganature.append(.string(signature.signature))
        }

        let arguments: [Cadence.Argument] = [
            .address(Address(hexString: address)),
            .string(message),
            .array(indices),
            .array(siganature),
        ]

        let verifyScript = try getVerifySignaturesScript(
            isAccountProof: false,
            fclCryptoContract: fclCryptoContract
        )
        let result = try await fcl.query(
            script: verifyScript,
            arguments: arguments
        )
        guard case let .bool(valid) = result.value else {
            throw FCLError.unexpectedResult
        }
        return valid
    }

    static func accountProofContractAddress(
        network: Network
    ) throws -> Address {
        switch network {
        case .mainnet:
            return Address(hexString: "0xb4b82a1c9d21d284")
        case .testnet:
            return Address(hexString: "0x74daa6f9c7ef24b1")
        case .canarynet,
                .sandboxnet,
                .emulator:
            throw FCLError.currentNetworkNotSupported
        }
    }

    static func getVerifySignaturesScript(
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
        import FCLCrypto from \(contractAddress.hexStringWithPrefix)

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

}
