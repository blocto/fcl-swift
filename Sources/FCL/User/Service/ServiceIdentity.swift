//
//  ServiceIdentity.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

struct ServiceIdentity: Decodable {
    public let fclType: String
    public let fclVersion: String
    public let address: String
    let keyId: Int
    
    enum CodingKeys: String, CodingKey {
        case fclType = "f_yype"
        case fclVersion = "f_vsn"
        case address
        case keyId
    }
}
