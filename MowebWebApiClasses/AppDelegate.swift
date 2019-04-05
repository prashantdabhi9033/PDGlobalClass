//
//  Created by Prashant Dabhi on 08/01/19.
//  Copyright © 2019 Prashant Dabhi. All rights reserved.
//
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, APIManagerDelegate {
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        APIManager.generalServerError = "General server error"
        APIManager.generalNoInternetError = "General Nertwork unreachable error"
        APIManager.shared.apiManagerDelegate = self
        
        APIManager.shared.register(defaultProperty: self.loadCommonParams(),            for: .commonParameters)
        APIManager.shared.register(defaultProperty: "h_!@e*&l%i$%o_s@t#o*w^e_*r!s@",    for: .headerKey)
        APIManager.shared.register(defaultProperty: "jsonData",                         for: .jsonParameterRootKey)
        APIManager.shared.register(defaultProperty: window,                             for: .apiFailureRetryViewParent)
        APIManager.shared.register(defaultProperty: APIFailureRetryView(),              for: .apiFailureRetryView)
        APIManager.shared.register(defaultProperty: true, for: .shouldShowAPIFailureRetryView)
        APIManager.shared.register(defaultProperty: true, for: .shouldParformAPIWhenInternetResume)
        
        return true
    }
    
    func loadCommonParams() -> Parameters {
        var commonParams = Parameters()
        commonParams["language"] = "english"
        commonParams["deviceToken"] = "asdasasadasda2212"
        commonParams["intUdid"] = "asdadasd21e1e2"
        commonParams["deviceType"] = "Iphone"
        
        return commonParams
    }
    
    func showProgressHUD(withMessage message: String?, senderVC: UIViewController, shouldShowProgressFlag: Bool) {
        print("showing progress for : \(senderVC.self)")
    }
    
    func hideProgressHUD(senderVC: UIViewController, shouldShowProgressFlag: Bool) {
        print("hiding for: \(senderVC.self)")
    }
    
    func showAlert(message: String, senderVC: UIViewController, shouldShowProgressFlag: Bool) {
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

