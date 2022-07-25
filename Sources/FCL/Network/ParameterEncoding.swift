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

    /// The encoding to use for `Array` parameters.
    static let arrayEncoding: ArrayEncoding = .brackets

    /// The encoding to use for `Bool` parameters.
    static let boolEncoding: BoolEncoding = .numeric

    /// Configures how `Array` parameters are encoded.
    enum ArrayEncoding {
        /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
        case brackets
        /// No brackets are appended. The key is encoded as is.
        case noBrackets

        func encode(key: String) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            }
        }
    }

    /// Configures how `Bool` parameters are encoded.
    enum BoolEncoding {
        /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
        case numeric
        /// Encode `true` and `false` as string literals.
        case literal

        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }

    static func encode(
        urlRequest: URLRequest,
        parameters: [String: Any],
        type: EncodingType
    ) throws -> URLRequest {
        var newURLRequest = urlRequest
        switch type {
        case .urlEncoding:
            guard let url = newURLRequest.url else {
                throw FCLError.parameterEncodingFailed
            }

            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                newURLRequest.url = urlComponents.url
            }
        case .jsonEncoding:
            let data = try JSONSerialization.data(
                withJSONObject: parameters,
                options: []
            )

            if var allHTTPHeaderFields = newURLRequest.allHTTPHeaderFields {
                allHTTPHeaderFields["Content-Type"] = "application/json"
                newURLRequest.allHTTPHeaderFields = allHTTPHeaderFields
            } else {
                newURLRequest.allHTTPHeaderFields = ["Content-Type": "application/json"]
            }

            newURLRequest.httpBody = data
        }
        return newURLRequest
    }

    private static func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    /// Creates a percent-escaped, URL encoded query string components from the given key-value pair recursively.
    ///
    /// - Parameters:
    ///   - key:   Key of the query component.
    ///   - value: Value of the query component.
    ///
    /// - Returns: The percent-escaped, URL encoded query string components.
    private static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        switch value {
        case let dictionary as [String: Any]:
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        case let array as [Any]:
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        case let number as NSNumber:
            if number.isBool {
                components.append((escape(key), escape(boolEncoding.encode(value: number.boolValue))))
            } else {
                components.append((escape(key), escape("\(number)")))
            }
        case let bool as Bool:
            components.append((escape(key), escape(boolEncoding.encode(value: bool))))
        default:
            components.append((escape(key), escape("\(value)")))
        }
        return components
    }

    /// Creates a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// - Parameter string: `String` to be percent-escaped.
    ///
    /// - Returns:          The percent-escaped `String`.
    private static func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed) ?? string
    }

}

extension NSNumber {
    
    var isBool: Bool {
        // Use Obj-C type encoding to check whether the underlying type is a `Bool`, as it's guaranteed as part of
        // swift-corelibs-foundation, per [this discussion on the Swift forums](https://forums.swift.org/t/alamofire-on-linux-possible-but-not-release-ready/34553/22).
        String(cString: objCType) == "c"
    }
    
}
