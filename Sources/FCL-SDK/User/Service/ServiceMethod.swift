//
//  ServiceMethod.swift
//  
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation

public enum ServiceMethod: String, Codable {
    case httpPost = "HTTP/POST"
    case httpGet = "HTTP/GET"
    case iframe = "VIEW/IFRAME"
    case iframeRPC = "IFRAME/RPC"
    case browserIframe = "BROWSER/IFRAME"
    case data = "DATA"
    case walletconnectRPC = "WC/RPC"
    
    var httpMethod: String? {
        switch self {
        case .httpGet:
            return "GET"
        case .httpPost:
            return "POST"
        default:
            return nil
        }
    }
}
