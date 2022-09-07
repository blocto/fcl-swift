//
//  FCL_SwiftUI_DemoApp.swift
//  FCL_SwiftUI_Demo
//
//  Created by Andrew Wang on 2022/9/6.
//

import SwiftUI
import FCL_SDK

@main
struct FCL_SwiftUI_DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    fcl.application(open: url)
                }
        }
    }
}
