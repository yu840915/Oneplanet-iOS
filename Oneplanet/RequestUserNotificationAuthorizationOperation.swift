//
//  RequestUserNotificationAuthorizationOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/29.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import UserNotifications

class RequestUserNotificationAuthorizationOperation: SimpleAsynchronousOperation {
    private(set) var granted: Bool?
    private(set) var error: Error?
    override func main() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {[weak self] (granted, error) in
            self?.didAuthorize(granted, error: error)
        }
    }
    
    private func didAuthorize(_ granted: Bool, error: Error?) {
        self.error = error
        self.granted = granted
        if let err = error {
            logger.error("Fail get user notification authorization, error: \(err)")
        }
    }
}

class UserNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if UIApplication.shared.applicationState == .active {
            completionHandler([])
        } else {
            completionHandler(.alert)
        }
    }
}
