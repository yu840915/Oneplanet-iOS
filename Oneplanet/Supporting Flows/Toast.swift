//
//  Toast.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/31.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import SwiftMessages

class Toast: UIView {
    class func config() {
        SwiftMessages.defaultConfig.presentationStyle = .top
        SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: .alert)
        SwiftMessages.defaultConfig.dimMode = .none
    }
    
    class func show(with message: String) {
        let view = UINib(nibName: "Toast", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Toast
        view.messageLabel.text = message
        SwiftMessages.show(view: view)
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    override var intrinsicContentSize: CGSize {
        let h: CGFloat = 40 + UIApplication.shared.statusBarFrame.height
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
    }
}
