//
//  Presentable.swift
//
//
//  Created by Andrew Wang on 2022/6/29.
//

import Foundation

protocol Presentable {

    func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    )

}
