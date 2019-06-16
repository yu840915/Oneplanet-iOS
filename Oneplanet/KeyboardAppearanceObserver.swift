//
//  KeyboardAppearanceObserver.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class KeyboardAppearanceObserver {
    private var keyboardChangeObserver: Any!
    var keyboardWillChange: ((ChangeInfo)->())?
    
    init() {
        keyboardChangeObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main, using: {[weak self] (notif) in
            self?.keyboardWillChange(notif)
        })
    }
    
    private func keyboardWillChange(_ notification: Notification) {
        let beginRect = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let endRect = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if beginRect == endRect {
            return
        }
        let duration: TimeInterval = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let curve: UIView.AnimationCurve = UIView.AnimationCurve(rawValue: (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue) ?? .linear
        keyboardWillChange?(ChangeInfo(beginRect: beginRect, endRect: endRect, duration: duration, animationCurve: curve))
    }
}

extension KeyboardAppearanceObserver {
    struct ChangeInfo {
        let beginRect: CGRect
        let endRect: CGRect
        let duration: TimeInterval
        let animationCurve: UIView.AnimationCurve
    }
}

typealias KeyboardChangeInfo = KeyboardAppearanceObserver.ChangeInfo
