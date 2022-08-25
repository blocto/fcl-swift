//
//  URLSessionExtension.swift
//
//
//  Created by Andrew Wang on 2022/7/6.
//

import UIKit

extension URLSession {

    static let decoder = JSONDecoder()

    func dataAuthnResponse(for request: URLRequest) async throws -> AuthResponse {
        log(message: request.toReadable())
        let data = try await data(for: request)
        log(message: String(data: try data.prettyData(), encoding: .utf8) ?? "")
        return try Self.decoder.decode(AuthResponse.self, from: data)
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
