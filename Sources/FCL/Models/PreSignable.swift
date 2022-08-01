//
//  PreSignable.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation
import Cadence

struct PreSignable: Encodable {
    let fclType: String = Pragma.preSignable.fclType
    let fclVersion: String = Pragma.preSignable.fclVersion
    let roles: Role
    let cadence: String
    var args: [Cadence.Argument] = []
    let data = [String: String]()
    var interaction = Interaction()

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
                interaction.arguments[tempId]
            },
            proposalKey: interaction.createProposalKey(),
            payer: interaction.payer,
            authorizers: interaction.authorizations
                .compactMap { cid in interaction.accounts[cid]?.address.hexString }
                .uniqued(),
            payloadSigs: insideSigners,
            envelopeSigs: outsideSigners
        )
    }

    enum CodingKeys: String, CodingKey {
        case fType = "f_type"
        case fVsn = "f_vsn"
        case roles, cadence, args, interaction
        case voucher
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fType)
        try container.encode(fclVersion, forKey: .fVsn)
        try container.encode(roles, forKey: .roles)
        try container.encode(cadence, forKey: .cadence)
        try container.encode(args, forKey: .args)
        try container.encode(interaction, forKey: .interaction)
        try container.encode(voucher, forKey: .voucher)
    }
}
