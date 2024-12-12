//
//  AppDelegate.swift
//  DevelopmentKit
//
//  Created by 姚旭 on 2024/12/12.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = TempViewController()
        window?.makeKeyAndVisible()
        return true
    }
    
}
