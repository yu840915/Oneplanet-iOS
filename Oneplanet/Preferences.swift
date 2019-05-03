//
//  Preferences.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class Preferences {
    static let hasWatchedWelcomeMessage = BoolPreferencesItem(key: "OPNHasWatchedWelcomeMessage")
    static let accessToken = StringPreferencesItem(key: "OPNAccessToken")
    static let profileNickname = StringPreferencesItem(key: "OPNProfileNickname")
    static let profileAvatarURL = URLPreferencesItem(key: "OPNProfileAvatarURL")
}

class PreferencesItem<T> {
    let key: String
    init(key: String) {
        self.key = key
    }
    
    var value: T? {
        set {}
        get { return nil }
    }
    
    var hasValue: Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}

class BoolPreferencesItem: PreferencesItem<Bool> {
    override var value: Bool? {
        get {
            return hasValue ? UserDefaults.standard.bool(forKey: key) : nil
        }
        set {
            if let bool = newValue {
                UserDefaults.standard.set(bool, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

class StringPreferencesItem: PreferencesItem<String> {
    override var value: String? {
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
        get {
            return UserDefaults.standard.string(forKey: key)
        }
    }
}

class URLPreferencesItem: PreferencesItem<URL> {
    override var value: URL? {
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
        get {
            return UserDefaults.standard.url(forKey: key)
        }
    }
}
