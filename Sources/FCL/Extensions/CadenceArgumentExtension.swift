//
//  CadenceArgumentExtension.swift
//  FCL
//
//  Created by Andrew Wang on 2022/7/27.
//

import Foundation
import Cadence

extension Cadence.Argument {

    func toFCLArgument() -> Argument {
        func randomString(length: Int) -> String {
            let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
            return String((0 ..< length).map { _ in letters.randomElement()! })
        }

        return Argument(
            kind: "ARGUMENT",
            tempId: randomString(length: 10),
            value: value,
            asArgument: self,
            xform: Xform(label: type.rawValue)
        )
    }

}

extension Array where Element == Cadence.Argument {

    func toFCLArguments() -> [(String, Argument)] {
        var list = [(String, Argument)]()
        forEach { arg in
            let fclArg = arg.toFCLArgument()
            list.append((fclArg.tempId, fclArg))
        }
        return list
    }

}
