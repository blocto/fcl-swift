//
//  ResponseStatus.swift
//  
//
//  Created by Andrew Wang on 2022/7/1.
//

import Foundation

public enum ResponseStatus: String, Decodable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case declined = "DECLINED"
}
