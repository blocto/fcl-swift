//
//  Interaction.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/25.
//

import Foundation
import FlowSDK
import Cadence
import BigInt

struct Interaction: Codable {
    var tag: Tag = .unknown
    var assigns = [String: String]()
    var status: Status = .ok
    var reason: String?
    var accounts = [String: SignableUser]()
    var params = [String: String]()
    var arguments = [String: Argument]()
    var message = Message()
    var proposer: String?
    var authorizations = [String]()
    var payer: String?
    var events = Events()
    var transaction = Id()
    var block = Block()
    var account = Account()
    var collection = Id()

    enum Status: String, CaseIterable, Codable {
        case ok = "OK"
        case bad = "BAD"
    }

    enum Tag: String, CaseIterable, Codable {
        case unknown = "UNKNOWN"
        case script = "SCRIPT"
        case transaction = "TRANSACTION"
        case getTransactionStatus = "GET_TRANSACTION_STATUS"
        case getAccount = "GET_ACCOUNT"
        case getEvents = "GET_EVENTS"
        case getLatestBlock = "GET_LATEST_BLOCK"
        case ping = "PING"
        case getTransaction = "GET_TRANSACTION"
        case getBlockById = "GET_BLOCK_BY_ID"
        case getBlockByHeight = "GET_BLOCK_BY_HEIGHT"
        case getBlock = "GET_BLOCK"
        case getBlockHeader = "GET_BLOCK_HEADER"
        case getCollection = "GET_COLLECTION"
    }

    @discardableResult
    mutating func setTag(_ tag: Tag) -> Self {
        self.tag = tag
        return self
    }

    var findInsideSigners: [String] {
        // Inside Signers Are: (authorizers + proposer) - payer
        var inside = Set(authorizations)
        if let proposer = proposer {
            inside.insert(proposer)
        }
        if let payer = payer {
            inside.remove(payer)
        }
        return Array(inside)
    }

    var findOutsideSigners: [String] {
        // Outside Signers Are: (payer)
        guard let payer = payer else {
            return []
        }
        let outside = Set([payer])
        return Array(outside)
    }

    func createProposalKey() -> ProposalKey {
        guard let proposer = proposer,
              let account = accounts[proposer],
              let sequenceNum = account.sequenceNum else {
            return ProposalKey()
        }

        return ProposalKey(
            address: account.address.hexString,
            keyId: Int(account.keyId),
            sequenceNum: Int(sequenceNum)
        )
    }

    func createFlowProposalKey() async throws -> Transaction.ProposalKey {
        guard let proposer = proposer,
              var account = accounts[proposer],
              let sequenceNumber = account.sequenceNum else {
            throw FCLError.invaildProposer
        }

        let address = account.address
        let keyId = account.keyId

        if let sequenceNum = account.sequenceNum {
            let key = Transaction.ProposalKey(
                address: address,
                keyIndex: Int(keyId),
                sequenceNumber: UInt64(sequenceNum)
            )
            return key
        } else {
            let remoteAccount = try await fcl.flowAPIClient.getAccountAtLatestBlock(address: address)
            guard let remoteAccount = remoteAccount else {
                throw FCLError.accountNotFound
            }
            account.sequenceNum = remoteAccount.keys[Int(keyId)].sequenceNumber
            let key = Transaction.ProposalKey(
                address: address,
                keyIndex: Int(keyId),
                sequenceNumber: sequenceNumber
            )
            return key
        }
    }

    func buildPreSignable(role: Role) -> PreSignable {
        PreSignable(
            roles: role,
            cadence: message.cadence ?? "",
            args: message.arguments.compactMap { tempId in arguments[tempId]?.asArgument },
            interaction: self
        )
    }

    func toFlowTransaction() async throws -> Transaction {
        let proposalKey = try await createFlowProposalKey()

        guard let payerAccount = payer,
              let payerAddress = accounts[payerAccount]?.address else {
            throw FCLError.missingPayer
        }

        var tx = try Transaction(
            script: Data((message.cadence ?? "").utf8),
            arguments: message.arguments.compactMap { tempId in arguments[tempId]?.asArgument },
            referenceBlockId: Identifier(hexString: message.refBlock ?? ""),
            gasLimit: message.computeLimit,
            proposalKey: proposalKey,
            payer: payerAddress,
            authorizers: authorizations
                .compactMap { cid in accounts[cid]?.address }
                .uniqued()
        )

        let insideSigners = findInsideSigners
        insideSigners.forEach { address in
            if let account = accounts[address],
               let signature = account.signature {
                tx.addPayloadSignature(
                    address: account.address,
                    keyIndex: Int(account.keyId),
                    signature: signature.hexDecodedData
                )
            }
        }

        let outsideSigners = findOutsideSigners
        outsideSigners.forEach { address in
            if let account = accounts[address],
               let signature = account.signature {
                tx.addEnvelopeSignature(
                    address: account.address,
                    keyIndex: Int(account.keyId),
                    signature: signature.hexDecodedData
                )
            }
        }
        return tx
    }

    enum CodingKeys: CodingKey {
        case tag
        case assigns
        case status
        case reason
        case accounts
        case params
        case arguments
        case message
        case proposer
        case authorizations
        case payer
        case events
        case transaction
        case block
        case account
        case collection
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Interaction.CodingKeys.self)
        try container.encode(tag, forKey: Interaction.CodingKeys.tag)
        try container.encode(assigns, forKey: Interaction.CodingKeys.assigns)
        try container.encode(status, forKey: Interaction.CodingKeys.status)
        try container.encodeIfPresent(reason, forKey: Interaction.CodingKeys.reason)
        try container.encode(accounts, forKey: Interaction.CodingKeys.accounts)
        try container.encode(params, forKey: Interaction.CodingKeys.params)
        try container.encode(arguments, forKey: Interaction.CodingKeys.arguments)
        try container.encode(message, forKey: Interaction.CodingKeys.message)
        try container.encodeIfPresent(proposer, forKey: Interaction.CodingKeys.proposer)
        try container.encode(authorizations, forKey: Interaction.CodingKeys.authorizations)
        try container.encodeIfPresent(payer, forKey: Interaction.CodingKeys.payer)
        try container.encode(events, forKey: Interaction.CodingKeys.events)
        try container.encode(transaction, forKey: Interaction.CodingKeys.transaction)
        try container.encode(block, forKey: Interaction.CodingKeys.block)
        try container.encode(account, forKey: Interaction.CodingKeys.account)
        try container.encode(collection, forKey: Interaction.CodingKeys.collection)
    }

}

struct Argument: Codable {

    var kind: String
    var tempId: String
    var value: Cadence.Value
    var asArgument: Cadence.Argument
    var xform: Xform

    enum CodingKeys: CodingKey {
        case kind
        case tempId
        case value
        case asArgument
        case xform
    }

    init(
        kind: String,
        tempId: String,
        value: Cadence.Value,
        asArgument: Cadence.Argument,
        xform: Xform
    ) {
        self.kind = kind
        self.tempId = tempId
        self.value = value
        self.asArgument = asArgument
        self.xform = xform
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(String.self, forKey: .kind)
        tempId = try container.decode(String.self, forKey: .tempId)
        // TODO: not yet support nested argument.
        asArgument = try container.decode(Cadence.Argument.self, forKey: .asArgument)
        value = asArgument.value
        xform = try container.decode(Xform.self, forKey: .xform)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Argument.CodingKeys.self)

        try container.encode(kind, forKey: Argument.CodingKeys.kind)
        try container.encode(tempId, forKey: Argument.CodingKeys.tempId)
        try container.encode(value, forKey: Argument.CodingKeys.value)
        try container.encode(asArgument, forKey: Argument.CodingKeys.asArgument)
        try container.encode(xform, forKey: Argument.CodingKeys.xform)
    }
}

struct Xform: Codable {
    var label: String
}

struct Id: Codable {
    var id: String?
}

let defaultComputeLimit: UInt64 = 100

struct Message: Codable {
    var cadence: String?
    var refBlock: String?
    var computeLimit: UInt64 = defaultComputeLimit
    var proposer: String?
    var payer: String?
    var authorizations: [String] = []
    var params: [String] = []
    var arguments: [String] = []
}

struct Events: Codable {
    var eventType: String?
    var start: String?
    var end: String?
    var blockIds: [String] = []
}

struct Block: Codable {
    var id: String?
    var height: Int64?
    var isSealed: Bool?
}

struct Account: Codable {
    var addr: String?
}

struct ProposalKey: Codable {
    var address: String?
    var keyId: Int?
    var sequenceNum: Int?
}
