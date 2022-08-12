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

struct Interaction: Encodable {
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
}

struct Argument: Encodable {
    var kind: String
    var tempId: String
    var value: Cadence.Value
    var asArgument: Cadence.Argument
    var xform: Xform
}

struct Xform: Codable {
    var label: String
}

struct Id: Encodable {
    var id: String?
}

let defaultComputeLimit: UInt64 = 100

struct Message: Encodable {
    var cadence: String?
    var refBlock: String?
    var computeLimit: UInt64 = defaultComputeLimit
    var proposer: String?
    var payer: String?
    var authorizations: [String] = []
    var params: [String] = []
    var arguments: [String] = []
}

struct Events: Encodable {
    var eventType: String?
    var start: String?
    var end: String?
    var blockIds: [String] = []
}

struct Block: Encodable {
    var id: String?
    var height: Int64?
    var isSealed: Bool?
}

struct Account: Encodable {
    var addr: String?
}

struct ProposalKey: Encodable {
    var address: String?
    var keyId: Int?
    var sequenceNum: Int?
}
