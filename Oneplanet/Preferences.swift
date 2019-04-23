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

