//
//  CadenceResolver.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation

final class CadenceResolver: Resolver {

    func resolve(ix: Interaction) async throws -> Interaction {
        guard let cadenceSript = ix.message.cadence else {
            throw FCLError.scriptNotFound
        }
        if ix.tag == .transaction || ix.tag == .script {
            var newIx = ix
            newIx.message.cadence = fcl.config.addressReplacements.reduce(cadenceSript) { result, replacement in
                result.replacingOccurrences(
                    of: replacement.placeholder,
                    with: replacement.replacement.hexStringWithPrefix
                )
            }
            return newIx
        }
        return ix
    }

}
