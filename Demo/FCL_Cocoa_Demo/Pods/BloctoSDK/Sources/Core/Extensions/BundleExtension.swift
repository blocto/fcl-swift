//
//  BundleExtension.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/4/26.
//

import Foundation

extension Bundle {

    static var resouceBundle: Bundle? {
#if COCOAPODS
        return Bundle(identifier: "org.cocoapods.BloctoSDK")
#elseif SWIFT_PACKAGE
        return Bundle.module
#else
        return nil
#endif
    }

}
