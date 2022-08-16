//
//  URLSessionExtension.swift
//
//
//  Created by Andrew Wang on 2022/7/6.
//

import UIKit

extension URLSession {

    static let decoder = JSONDecoder()

    func dataDecode<Model: Decodable>(for request: URLRequest) async throws -> Model {
        let data = try await data(for: request)
        return try Self.decoder.decode(Model.self, from: data)
    }

    func dataAuthnResponse(for request: URLRequest) async throws -> AuthResponse {
        let data = try await data(for: request)
        return try Self.decoder.decode(AuthResponse.self, from: data)
    }

    func dataPollingWrappedResponse<Model: Decodable>(for request: URLRequest) async throws -> Model {
        let data = try await data(for: request)
        let pollingWrappedResponse = try Self.decoder.decode(PollingWrappedResponse<Model>.self, from: data)
        guard let data = pollingWrappedResponse.data else {
            throw FCLError.responseUnexpected
        }
        return data
    }

    private func data(for request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            dataTask(with: request) { data, _, error in
                if let error = error {
                    continuation.resume(with: .failure(error))
                } else if let data = data {
                    continuation.resume(with: .success(data))
                } else {
                    continuation.resume(with: .failure(FCLError.responseUnexpected))
                }
            }.resume()
        }
    }

}
