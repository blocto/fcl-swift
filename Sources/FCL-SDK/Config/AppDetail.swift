//
//  AppDetail.swift
//  FCL
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation
import SwiftyJSON

public struct AppDetail: Encodable {

    let title: String
    let icon: URL?
    var custom: [String: Encodable] = [:]
    
    enum CodingKeys: String, CodingKey {
        case title
        case icon
    }

    public init(
        title: String,
        icon: URL?,
        custom: [String: Encodable] = [:]
    ) {
        self.title = title
        self.icon = icon
        self.custom = custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(icon, forKey: .icon)
        var dynamicContainer = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in custom {
            if let codingKey = DynamicKey(stringValue: key) {
                try dynamicContainer.encode(value, forKey: codingKey)
            }
        }
    }

}
