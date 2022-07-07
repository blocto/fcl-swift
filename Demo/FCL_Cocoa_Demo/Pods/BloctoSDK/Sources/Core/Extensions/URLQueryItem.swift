//
//  URLQueryItem.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/14.
//

import Foundation

extension URLQueryItem {

    init(name: QueryName, value: String?) {
        self.init(name: name.rawValue, value: value)
    }

}
