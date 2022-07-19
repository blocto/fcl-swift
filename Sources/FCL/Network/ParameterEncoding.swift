//
//  ParameterEncoding.swift
//  
//
//  Created by Andrew Wang on 2022/7/18.
//

import Foundation

public enum EncodingType {
    case urlEncoding
    case jsonEncoding
}

public enum ParameterEncoding {
    
    static func encode(parameters: [String: Any], type: EncodingType) throws -> URLRequest {
        switch type {
        case .urlEncoding:
            guard let url = urlRequest.url else {
                throw AFError.parameterEncodingFailed(reason: .missingURL)
            }
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            }
        case .jsonEncoding:
            let data = try JSONSerialization.data(withJSONObject: parameters, options: options)
        }
    }
    
}
