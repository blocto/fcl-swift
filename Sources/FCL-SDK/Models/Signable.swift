//
//  Signable.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/30.
//

import Foundation
import Cadence

struct Signable: Encodable {

    let fclType: String = Pragma.signable.fclType
    let fclVersion: String = Pragma.signable.fclVersion
    let data = [String: String]()
    let message: String
    let keyId: UInt32
    let address: Cadence.Address
    let roles: Role
    let cadence: String?
    let args: [Cadence.Argument]
    let interaction: Interaction

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address = "addr"
        case roles
        case data
        case message
        case keyId
        case cadence
        case args
        case interaction
        case voucher
    }

    var voucher: Voucher {
        let insideSigners: [Singature] = interaction.findInsideSigners.compactMap { id in
            guard let account = interaction.accounts[id] else { return nil }
            return Singature(
                address: account.address.hexString,
                keyId: account.keyId,
                sig: account.signature
            )
        }

        let outsideSigners: [Singature] = interaction.findOutsideSigners.compactMap { id in
            guard let account = interaction.accounts[id] else { return nil }
            return Singature(
                address: account.address.hexString,
                keyId: account.keyId,
                sig: account.signature
            )
        }

        return Voucher(
            cadence: interaction.message.cadence,
            refBlock: interaction.message.refBlock,
            computeLimit: interaction.message.computeLimit,
            arguments: interaction.message.arguments.compactMap { tempId in
                interaction.arguments[tempId]?.asArgument
            },
            proposalKey: interaction.createProposalKey(),
            payer: interaction.accounts[interaction.payer ?? ""]?.address.hexString,
            authorizers: interaction.authorizations
                .compactMap { cid in interaction.accounts[cid]?.address.hexString }
                .uniqued(),
            payloadSigs: insideSigners,
            envelopeSigs: outsideSigners
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fclType)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encode(data, forKey: .data)
        try container.encode(message, forKey: .message)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(roles, forKey: .roles)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(address.hexString, forKey: .address)
        try container.encode(args, forKey: .args)
        try container.encode(interaction, forKey: .interaction)
        try container.encode(voucher, forKey: .voucher)
    }

}
