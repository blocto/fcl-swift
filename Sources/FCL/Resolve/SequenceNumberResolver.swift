//
//  SequenceNumberResolver.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Cadence
import Foundation

final class SequenceNumberResolver: Resolver {

    func resolve(ix: Interaction) async throws -> Interaction {
        guard let proposer = ix.proposer,
              let account = ix.accounts[proposer] else {
            throw FCLError.internal
        }
        
        if account.sequenceNum == nil {
            let remoteAccount = try await fcl.flowAPIClient.getAccountAtLatestBlock(address: account.address)
            guard let remoteAccount = remoteAccount else {
                throw FCLError.accountNotFound
            }
            var newIX = ix
            newIX.accounts[proposer]?.sequenceNum = remoteAccount.keys[Int(account.keyId)].sequenceNumber
            return newIX
        } else {
            return ix
        }
    }

}
