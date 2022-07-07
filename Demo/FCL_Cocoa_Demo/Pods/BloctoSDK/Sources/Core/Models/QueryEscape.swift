//
//  QueryEscape.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/5/13.
//

import Foundation

enum QueryEscape {

    static func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? string
    }

}
