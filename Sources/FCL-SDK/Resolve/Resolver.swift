//
//  Resolver.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/26.
//

import Foundation

protocol Resolver {
    func resolve(ix: Interaction) async throws -> Interaction
}
