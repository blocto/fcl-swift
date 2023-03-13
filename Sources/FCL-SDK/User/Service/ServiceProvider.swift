//
//  ServiceProvider.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public struct ServiceProvider: Codable {
    public let fclType: String
    public let fclVersion: String
    public let address: String?
    public let name: String?
    public let iconString: String?

    public var iconURL: URL? {
        if let iconString = iconString {
            return URL(string: iconString)
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case address
        case name
        case iconString = "icon"
    }

    public init(
        address: String,
        name: String,
        iconString: String
    ) {
        self.fclType = ""
        self.fclVersion = ""
        self.address = address
        self.name = name
        self.iconString = iconString
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fclType, forKey: .fclType)
        try container.encode(fclVersion, forKey: .fclVersion)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(iconString, forKey: .iconString)
    }
}
