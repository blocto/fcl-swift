//
//  Pragma.swift
//
//
//  Created by Andrew Wang on 2022/7/14.
//

import Foundation

struct Pragma {

    static let user = Pragma(fclType: "USER", fclVersion: Constants.fclVersion)
    static let provider = Pragma(fclType: "Provider", fclVersion: Constants.fclVersion)
    static let service = Pragma(fclType: "Service", fclVersion: Constants.fclVersion)
    static let identity = Pragma(fclType: "Identity", fclVersion: Constants.fclVersion)
    static let pollingResponse = Pragma(fclType: "PollingResponse", fclVersion: Constants.fclVersion)
    static let compositeSignature = Pragma(fclType: "CompositeSignature", fclVersion: Constants.fclVersion)
    static let openId = Pragma(fclType: "OpenId", fclVersion: Constants.fclVersion)
    static let preSignable = Pragma(fclType: "PreSignable", fclVersion: "1.0.1")
    static let signable = Pragma(fclType: "Signable", fclVersion: "1.0.1")

    let fclType: String
    let fclVersion: String

}
