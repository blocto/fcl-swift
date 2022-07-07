//
//  ServiceProvider.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

struct ServiceProvider: Decodable {
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
}
