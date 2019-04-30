//
//  AppLifeCycleObserver.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class AppLifeCycleObserver {
    private var notificationRegistration: Any!
    let observers = MulticastCallbackNode<(UIApplication.State)->()>()
    
    fileprivate init(event: Notification.Name) {
        notificationRegistration = NotificationCenter.default.addObserver(forName: event, object: nil, queue: .main, using: {[weak self] (_) in
            self?.invokeCallbacks()
        })
    }
    
    private func invokeCallbacks() {
        observers.invokeEach{$0(UIApplication.shared.applicationState)}
    }
}

extension AppLifeCycleObserver {
    static let willResignActive = AppLifeCycleObserver(event: UIApplication.willResignActiveNotification)
    static let didBecomeActive = AppLifeCycleObserver(event: UIApplication.didBecomeActiveNotification)
    static let didEnterBackground = AppLifeCycleObserver(event: UIApplication.didEnterBackgroundNotification)
    static let willEnterForeground = AppLifeCycleObserver(event: UIApplication.willEnterForegroundNotification)
    static let willTerminate = AppLifeCycleObserver(event: UIApplication.willTerminateNotification)
}
