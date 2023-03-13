//
//  PreSignable.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation
import Cadence

public struct PreSignable: Codable {
    private(set) var fclType: String = Pragma.preSignable.fclType
    private(set) var fclVersion: String = Pragma.preSignable.fclVersion
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
                interaction.arguments[tempId]?.asArgument
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
        case roles
        case cadence
        case args
        case interaction
        case voucher
    }

    init(
        roles: Role,
        cadence: String,
        args: [Cadence.Argument] = [],
        interaction: Interaction = Interaction()
    ) {
        self.roles = roles
        self.cadence = cadence
        self.args = args
        self.interaction = interaction
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        self.fclType = try container.decode(String.self, forKey: .fType)
        self.fclVersion = try container.decode(String.self, forKey: .fVsn)
        self.roles = try container.decode(Role.self, forKey: .roles)
        self.cadence = try container.decode(String.self, forKey: .cadence)
        self.args = try container.decode([Cadence.Argument].self, forKey: .args)
        self.interaction = try container.decode(Interaction.self, forKey: .interaction)
    }

    public func encode(to encoder: Encoder) throws {
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
