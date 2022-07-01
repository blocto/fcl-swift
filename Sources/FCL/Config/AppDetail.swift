//
//  AppDetail.swift
//  
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation

public struct AppDetail {
    
    let title: String
    let icon: URL?
    var custom: [String: Any] = [:]
    
    public init(
        title: String,
        icon: URL?,
        custom: [String: Any] = [:]
    ) {
        self.title = title
        self.icon = icon
        self.custom = custom
    }
}
