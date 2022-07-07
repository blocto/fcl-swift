//
//  URLComponents.swift
//  Alamofire
//
//  Created by Andrew Wang on 2022/3/14.
//

import Foundation

extension URLComponents {

    func getRequestId() -> UUID? {
        guard let uuidString = queryItems?.first(where: { $0.name == QueryName.requestId.rawValue })?.value else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    func queryItem(for queryName: QueryName) -> String? {
        return queryItems?.first(where: { $0.name == queryName.rawValue })?.value
    }

}
