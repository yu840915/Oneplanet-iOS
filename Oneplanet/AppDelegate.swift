//
//  AppDelegate.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDynamicLinks
import UserNotifications
import FacebookCore
import TwitterKit
import StoreKit
import ModelBlocks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private(set) var notificationDelegate: UserNotificationDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SKPaymentQueue.default().add(IAPTransactionProcessor.shared)
        setUpLogger()
        FirebaseApp.configure()
        DefaultStyleConfiguration.config()
        FirebaseMessagingSession.current = FirebaseMessagingSession()
        setUpUserNotificationDelegate()
        application.registerForRemoteNotifications()
        if let url = launchOptions?[.url] as? URL {
            router.handle(url)
        }
        appConfiguration.update()
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        TWTRTwitter.sharedInstance().start(withConsumerKey:TwitterCredentials.key, consumerSecret:TwitterCredentials.secret)
        WXApi.registerApp("wx8630436ab3a5f7c2")
//        prepareDataStore()
        return true
    }
    
    private func prepareDataStore() {
        let op = PrepareDataStoreOperation()
        op.start()
        DataStore.shared = op.dataStore
    }
    
    private func setUpUserNotificationDelegate() {
        let delegate = UserNotificationDelegate()
        notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FirebaseMessagingSession.current.setUpDeviceToken(deviceToken)
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.error("Cannot register for remote notification, error: \(error)")
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let pageUrl = userActivity.webpageURL else {
            return false
        }
        let handled = DynamicLinks.dynamicLinks().handleUniversalLink(pageUrl) { (dynamiclink, error) in
            if let url = dynamiclink?.url {
                router.handle(url)
            }
        }
        return handled
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.newData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return router.handle(url) || SDKApplicationDelegate.shared.application(app, open: url, options: options) || TWTRTwitter.sharedInstance().application(app, open: url, options: options) || WXApi.handleOpen(url, delegate: WeChatLogInOperation.runningLogIn ?? self)
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

extension AppDelegate: WXApiDelegate {
}


class StatusBarFrameObserver {
    static let shared = UIApplication.shared.keyWindow!.isXgenerationScreen ? StatusBarFrameObserver() : PreXGenScreenStatusBarFrameObserver()
    let statusBarHeightChangeObserverse = MulticastCallbackNode<()->()>()
    var extraBarHeight: CGFloat { return .zero }
    
    init() {
    }
}

class PreXGenScreenStatusBarFrameObserver: StatusBarFrameObserver {
    override var extraBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height - 20
    }
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: UIApplication.didChangeStatusBarFrameNotification, object: nil, queue: .main) {[weak self] (_) in
            self?.statusBarHeightChangeObserverse.invokeEach{$0()}
        }
    }
}
