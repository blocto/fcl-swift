//
//  SignatureResolver.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation
import FlowSDK

final class SignatureResolver: Resolver {

    func resolve(ix interaction: Interaction) async throws -> Interaction {
        var ix = interaction

        guard ix.tag == .transaction else {
            throw FCLError.internal
        }

        let insideSigners = interaction.findInsideSigners

        let tx = try await ix.toFlowTransaction()

        let payloadSignatureMap = try await withThrowingTaskGroup(
            of: (id: String, signature: String).self,
            returning: [String: String].self,
            body: { taskGroup in

                let insidePayload = tx.encodedPayload.toHexString()

                let interaction = ix
                for address in insideSigners {
                    taskGroup.addTask {
                        try await self.fetchSignature(
                            ix: interaction,
                            payload: insidePayload,
                            id: address
                        )
                    }
                }

                var returning: [String: String] = [:]
                for try await result in taskGroup {
                    returning[result.id] = result.signature
                }
                return returning
            }
        )

        payloadSignatureMap.forEach { id, signature in
            ix.accounts[id]?.signature = signature
        }

        let outsideSigners = ix.findOutsideSigners
        let envelopeSignatureMap = try await withThrowingTaskGroup(
            of: (id: String, signature: String).self,
            returning: [String: String].self,
            body: { taskGroup in

                let envelopeMessage = encodeEnvelopeMessage(
                    transaction: tx,
                    ix: ix,
                    insideSigners: insideSigners
                )

                let interaction = ix
                for address in outsideSigners {
                    taskGroup.addTask {
                        try await self.fetchSignature(
                            ix: interaction,
                            payload: envelopeMessage,
                            id: address
                        )
                    }
                }
                var returning: [String: String] = [:]
                for try await result in taskGroup {
                    returning[result.id] = result.signature
                }
                return returning
            }

        )
        envelopeSignatureMap.forEach { id, signature in
            ix.accounts[id]?.signature = signature
        }
        return ix
    }

    func fetchSignature(
        ix: Interaction,
        payload: String,
        id: String
    ) async throws -> (id: String, signature: String) {
        guard let account = ix.accounts[id],
              let signable = buildSignable(
                  ix: ix,
                  payload: payload,
                  account: account
              ),
              let data = try? JSONEncoder().encode(signable) else {
            throw FCLError.internal
        }

        let response = try await account.signingFunction(data)
        return (id: id, signature: (response.data?.signature ?? response.compositeSignature?.signature) ?? "")
    }

    func encodeEnvelopeMessage(
        transaction: Transaction,
        ix: Interaction,
        insideSigners: [String]
    ) -> String {
        var tx = transaction
        insideSigners.forEach { address in
            if let account = ix.accounts[address],
               let signature = account.signature {
                tx.addPayloadSignature(
                    address: account.address,
                    keyIndex: Int(account.keyId),
                    signature: signature.hexDecodedData
                )
            }
        }

        return tx.encodedEnvelope.toHexString()
    }

    func buildSignable(
        ix: Interaction,
        payload: String,
        account: SignableUser
    ) -> Signable? {
        Signable(
            message: payload,
            keyId: account.keyId,
            address: account.address,
            roles: account.role,
            cadence: ix.message.cadence,
            args: ix.message.arguments.compactMap { tempId in
                ix.arguments[tempId]?.asArgument
            },
            interaction: ix
        )
    }

}
