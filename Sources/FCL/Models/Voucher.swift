//
//  Voucher.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation
import Cadence

struct Voucher: Encodable {
    let cadence: String?
    let refBlock: String?
    let computeLimit: UInt64
    let arguments: [Cadence.Argument]
    let proposalKey: ProposalKey
    var payer: String?
    let authorizers: [String]?
    let payloadSigs: [Singature]?
    let envelopeSigs: [Singature]?
}
