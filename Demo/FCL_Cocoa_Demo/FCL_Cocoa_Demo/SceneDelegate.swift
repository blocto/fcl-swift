//
//  SceneDelegate.swift
//  FCL_Cocoa_Demo
//
//  Created by Andrew Wang on 2022/7/7.
//

import UIKit
import FCL_SDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.userActivities.first?.webpageURL {
            fcl.application(open: url)
        }
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = FlowDemoViewController()
        window?.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            fcl.application(open: context.url)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        fcl.continueForLinks(userActivity)
    }

}
