//
//  TaskExtension.swift
//
//
//  Created by Andrew Wang on 2022/7/6.
//

import Foundation

extension Task where Success == Never, Failure == Never {

    public
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }

}
