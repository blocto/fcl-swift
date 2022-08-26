//
//  FCLDelegate.swift
//  
//
//  Created by Andrew Wang on 2022/7/6.
//

import Foundation
import AuthenticationServices

public protocol FCLDelegate {
    func webAuthenticationContextProvider() -> ASPresentationAnchor?
}
