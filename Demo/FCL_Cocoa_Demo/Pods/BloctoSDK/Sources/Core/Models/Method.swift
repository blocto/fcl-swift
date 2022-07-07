//
//  Method.swift
//  Alamofire
//
//  Created by Andrew Wang on 2022/3/14.
//

import Foundation

public protocol Method {
    var id: UUID { get }
    var type: String { get }

    func encodeToURL(appId: String, baseURLString: String) throws -> URL?
    func resolve(components: URLComponents, logging: Bool)
    func handleError(error: Swift.Error)
}
