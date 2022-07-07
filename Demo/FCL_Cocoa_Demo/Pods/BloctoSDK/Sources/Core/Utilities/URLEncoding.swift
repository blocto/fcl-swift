//
//  URLEncoding.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/21.
//

import Foundation

public enum URLEncoding {

    static func queryItems(
        appId: String,
        requestId: String,
        blockchain: Blockchain
    ) -> [QueryItem] {
        let queryItems = [
            QueryItem(name: .appId, value: appId),
            QueryItem(name: .requestId, value: requestId),
            QueryItem(name: .blockchain, value: blockchain.rawValue)
        ]
        return queryItems
    }

    static func encode(_ queryItems: [QueryItem]) -> [URLQueryItem] {
        queryItems.flatMap { $0.getQueryComponents }
    }

    static func queryComponents(fromKey key: String, value: Any) -> [URLQueryItem] {
        var components: [URLQueryItem] = []
        switch value {
        case let dictionary as [String: Any]:
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        case let array as [Any]:
            let arrayEncoding = ArrayEncoding()
            for value in array {
                components += queryComponents(fromKey: arrayEncoding.encode(key: key), value: value)
            }
        case let number as NSNumber:
            if number.isBool {
                let boolEncoding = BoolEncoding()
                components.append(
                    .init(
                        name: escape(key),
                        value: escape(boolEncoding.encode(value: number.boolValue))))
            } else {
                components.append(
                    .init(
                        name: escape(key),
                        value: escape("\(number)")))
            }
        case let bool as Bool:
            let boolEncoding = BoolEncoding()
            components.append(
                .init(
                    name: escape(key),
                    value: escape(boolEncoding.encode(value: bool))))
        case let data as Data:
            components.append(
                .init(
                    name: escape(key),
                    value: escape(data.bloctoSDK.hexStringWith0xPrefix)))
        default:
            components.append(
                .init(
                    name: escape(key),
                    value: escape("\(value)")))
        }
        return components
    }
    
    static func solanaAppendMessagesQueryItems(dictionary: [String: Data]) -> [URLQueryItem] {
        var components: [URLQueryItem] = []
        for (nestedKey, value) in dictionary {
            components.append(
                .init(
                    name: escape("\(QueryName.appendTx.rawValue)[\(nestedKey)]"),
                    value: escape(value.bloctoSDK.hexString)))
        }
        return components
    }

    private static func escape(_ string: String) -> String {
        QueryEscape.escape(string)
    }

}

struct ArrayEncoding {

    func encode(key: String) -> String {
        "\(key)[]"
    }

}

struct DictionaryEncoding {

    func encode(
        key: String,
        value: [String: Any]
    ) -> String {
        "\(key)[]"
    }

}

struct BoolEncoding {

    func encode(value: Bool) -> String {
        value ? "true" : "false"
    }

}

extension CharacterSet {
    /// Creates a CharacterSet from RFC 3986 allowed characters.
    ///
    /// RFC 3986 states that the following characters are "reserved" characters.
    ///
    /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
    /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
    ///
    /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
    /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
    /// should be percent-escaped in the query string.
    public static let afURLQueryAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
    }()

}
