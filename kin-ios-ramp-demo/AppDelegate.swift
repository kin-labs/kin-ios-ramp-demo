//
//  AppDelegate.swift
//  kin-ios-ramp-demo
//
//  Created by Richard Reitzfeld on 5/16/21.
//  Copyright © 2021 Richard Reitzfeld. All rights reserved.
//

import UIKit
import KinBase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Public Properties

    var window: UIWindow?

    // MARK: - Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let viewController = ViewController()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
        
        return true
    }
}
