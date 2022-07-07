//
//  UIWindowExtension.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/30.
//

import Foundation
import AuthenticationServices

extension UIWindow: ASWebAuthenticationPresentationContextProviding {

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self
    }

}
