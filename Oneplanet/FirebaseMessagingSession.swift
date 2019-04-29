//
//  FirebaseMessagingSession.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/29.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Firebase

class FirebaseMessagingSession: NSObject, MessagingDelegate {
    static var current: FirebaseMessagingSession!
    let didUpdateToken = MulticastCallbackNode<(String)->()>()
    var token: String? {
        return Messaging.messaging().fcmToken
    }

    override init() {
        super.init()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        fetchInstanceID()
    }
    
    private func fetchInstanceID() {
        InstanceID.instanceID().getID {[weak self] (id, error) in
            self?.didFetchInstanceID(id, error: error)
        }
    }
    
    private func didFetchInstanceID(_ id: String?, error: Error?) {
        if let id = id {
            logger.debug("Did fetch Firebase instance ID \(id)")
        } else if let err = error {
            logger.error("Cannot fetch Firebase instance ID, error \(err)")
        }
    }

    
    func setUpDeviceToken(_ data: Data) {
        Messaging.messaging().apnsToken = data
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        didUpdateToken.invokeEach{$0(fcmToken)}
        logger.debug("Receive FCM token: \(fcmToken)")
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        logger.debug("Receive FCM remote message: \(remoteMessage.appData)")
    }
    
    func invalidate() {
        InstanceID.instanceID().deleteID {[weak self] (error) in
            self?.didInvalidate(error)
        }
    }
    
    private func didInvalidate(_ error: Error?) {
        if let err = error {
            logger.error("Cannot delete Firebase instance ID, error: \(err)")
        } else {
            logger.debug("Did delete Firebase instance ID")
        }
    }
}
