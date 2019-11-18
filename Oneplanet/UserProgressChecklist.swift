//
//  UserProgressChecklist.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class UserProgressChecklist {
    static let watchWelcomeMessage = ChecklistItem(Preferences.hasWatchedWelcomeMessage)
}

class ChecklistItem {
    private let preferenceItem: BoolPreferencesItem
    init(_ preferenceItem: BoolPreferencesItem) {
        self.preferenceItem = preferenceItem
    }
    
    var isFinished: Bool {
        return preferenceItem.value == true
    }
    
    func markAsFinished() {
        preferenceItem.value = true
    }
}
