//
//  AppConfiguration.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import FirebaseRemoteConfig

let appConfiguration: AppConfiguration = AppConfiguration()

class AppConfiguration {
    let didUpdateObservers = MulticastCallbackNode<()->()>()
    private let source: RemoteConfig
    fileprivate init() {
        source = RemoteConfig.remoteConfig()
        update()
    }
    
    func update() {
        source.fetch {[weak self] (status, error) in
            self?.didFetch(status, error: error)
        }
    }
    
    private func didFetch(_ status: RemoteConfigFetchStatus, error: Error?) {
        if status == .success {
            if source.activateFetched() {
                didUpdateObservers.invokeEach{$0()}
            }
        } else {
            logger.debug("Cannot fetch remote config, status \(status), error \(error?.localizedDescription ?? "n.a.")")
        }
    }
}

class AppConfigurationItem<ValueType>: CustomDebugStringConvertible {
    let key: String
    private let source: RemoteConfig
    init(key: String, source: RemoteConfig) {
        self.key = key
        self.source = source
    }
    
    var value: ValueType? {
        return nil
    }
    var configValue: RemoteConfigValue {
        return source.configValue(forKey: key)
    }
    
    var debugDescription: String {
        if let val = value {
            return "\(key): \(val)"
        }
        return "\(key): n.a."
    }
}

class AppConfigurationStringItem: AppConfigurationItem<String> {
    override var value: String? {
        return configValue.stringValue
    }
}
