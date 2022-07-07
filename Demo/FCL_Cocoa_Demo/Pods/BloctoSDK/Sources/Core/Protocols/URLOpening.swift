//
//  URLOpening.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/21.
//

import UIKit

public protocol URLOpening {
    func open(
        _ url: URL,
        options: [UIApplication.OpenExternalURLOptionsKey: Any],
        completionHandler completion: ((Bool) -> Void)?)
}

extension UIApplication: URLOpening {}
