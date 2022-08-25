//
//  ClientInfo.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/30.
//

import Foundation

struct ClientInfo: Encodable {

    let fclVersion: String = Constants.fclVersion
    let fclLibrary: String = "https://github.com/portto/fcl-swift"
    let hostname: String? = nil

    enum CodingKeys: String, CodingKey {
        case fclVersion
        case fclLibrary
        case hostname
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encode(fclLibrary, forKey: .fclLibrary)
        try container.encode(hostname, forKey: .hostname)
    }

}
