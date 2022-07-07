//
//  URLSessionExtension.swift
//  
//
//  Created by Andrew Wang on 2022/7/6.
//

import UIKit

extension URLSession {
    
    static let decoder = JSONDecoder()
    
    async func dataDecode<Model: Decodable>(for request: URLRequest) throws -> Model {
        let (data, _) = await data(for: request)
        return try decoder.decode(Model.self, from: data)
    }
    
    async func dataPollingResponse(for request: URLRequest) throws -> PollingResponse {
        let (data, _) = await data(for: request)
        return try decoder.decode(PollingResponse.self, from: data)
    }
    
    async func dataPollingWrappedResponse<Model: Decodable>(for request: URLRequest) throws -> Model {
        let (data, _) = await data(for: request)
        let  try decoder.decode(PollingWrappedResponse<Model>.self, from: data)
    }
    
}
