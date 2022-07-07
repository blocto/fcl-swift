//
//  QueryItem.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/16.
//

import Foundation

public struct QueryItem {

    let name: QueryName
    let value: Any

    init(name: QueryName, value: Any) {
        self.name = name
        self.value = value
    }

    var getQueryComponents: [URLQueryItem] {
        URLEncoding.queryComponents(fromKey: name.rawValue, value: value)
    }

}
