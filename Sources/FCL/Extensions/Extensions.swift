//
//  Extensions.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/27.
//

import Foundation

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension String {

    public var hexDecodedData: Data {
        // Convert to a CString and make sure it has an even number of characters (terminating 0 is included, so we
        // check for uneven!)
        guard let cString = cString(using: .ascii), (cString.count % 2) == 1 else {
            return Data()
        }

        var result = Data(capacity: (cString.count - 1) / 2)
        for i in stride(from: 0, to: cString.count - 1, by: 2) {
            guard let l = hexCharToByte(cString[i]),
                    let r = hexCharToByte(cString[i + 1]) else {
                return Data()
            }
            var value: UInt8 = (l << 4) | r
            result.append(&value, count: MemoryLayout.size(ofValue: value))
        }
        return result
    }

    func sansPrefix() -> String {
        if hasPrefix("0x") || hasPrefix("Fx") {
            return String(dropFirst(2))
        }
        return self
    }
    
    private func hexCharToByte(_ c: CChar) -> UInt8? {
        if c >= 48 && c <= 57 { // 0 - 9
            return UInt8(c - 48)
        }
        if c >= 97 && c <= 102 { // a - f
            return UInt8(10) + UInt8(c - 97)
        }
        if c >= 65 && c <= 70 { // A - F
            return UInt8(10) + UInt8(c - 65)
        }
        return nil
    }

}

extension URLRequest {
    
    func toReadable() -> String {
        var result = httpMethod ?? ""
        result.append("\n\n")
        let urlString = url?.absoluteString ?? ""
        
        result.append(urlString)
        result.append("\n\n")
        do {
            if let header = allHTTPHeaderFields {
                let headerData = try JSONSerialization.data(withJSONObject: header, options: .prettyPrinted)
                result.append(String(data: headerData, encoding: .utf8) ?? "")
                result.append("\n\n")
            }
            if let body = httpBody {
                let object = try JSONSerialization.jsonObject(with: body, options: .fragmentsAllowed)
                let bodyData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
                result.append(String(data: bodyData, encoding: .utf8) ?? "")
                result.append("\n\n")
            }
        } catch {
            debugPrint(error)
        }
        return result
    }
    
}

extension Data {
    
    func prettyData() throws -> Data {
        let object = try JSONSerialization.jsonObject(with: self, options: .fragmentsAllowed)
        return try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
    }
    
}
