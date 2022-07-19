//
//  Pragma.swift
//
//
//  Created by Andrew Wang on 2022/7/14.
//

import Foundation

struct Pragma {

    static let userPragma = Pragma(fclType: "USER", fclVersion: Constants.fclVersion)
    static let providerPragma = Pragma(fclType: "Provider", fclVersion: Constants.fclVersion)
    static let servicePragma = Pragma(fclType: "Service", fclVersion: Constants.fclVersion)
    static let identityPragma = Pragma(fclType: "Identity", fclVersion: Constants.fclVersion)
    static let pollingResponsePragma = Pragma(fclType: "PollingResponse", fclVersion: Constants.fclVersion)
    static let compositeSignaturePragma = Pragma(fclType: "CompositeSignature", fclVersion: Constants.fclVersion)
    static let openIdPragma = Pragma(fclType: "OpenId", fclVersion: Constants.fclVersion)

    let fclType: String
    let fclVersion: String

}
