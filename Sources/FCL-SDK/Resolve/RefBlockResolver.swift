//
//  RefBlockResolver.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation
import FlowSDK

final class RefBlockResolver: Resolver {

    func resolve(ix: Interaction) async throws -> Interaction {
        let block = try await fcl.flowAPIClient.getLatestBlock(isSealed: true)
        var newIX = ix
        newIX.message.refBlock = block?.blockHeader.id.hexString
        return newIX
    }

}
