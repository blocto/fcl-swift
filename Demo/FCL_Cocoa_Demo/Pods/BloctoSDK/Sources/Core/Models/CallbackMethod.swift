//
//  CallbackMethod.swift
//  BloctoSDK
//
//  Created by Andrew Wang on 2022/3/14.
//

import Foundation

public protocol CallbackMethod: Method {
    associatedtype Response
    typealias Callback = ((Result<Response, Swift.Error>) -> Void)

    var callback: Callback { get }
}
