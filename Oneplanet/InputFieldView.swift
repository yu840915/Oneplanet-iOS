//
//  InputFieldView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class InputFieldView: UIView {
    @IBOutlet weak var normalBackgroundImage: UIImageView!
    @IBOutlet weak var rejectingBackgroundImage: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    var isRejecting = false {
        didSet {
            updateWithRejectingState()
        }
    }
    
    override func awakeFromNib() {
        updateWithRejectingState()
    }
    
    private func updateWithRejectingState() {
        if isRejecting {
            normalBackgroundImage.isHidden = true
            rejectingBackgroundImage.isHidden = false
        } else {
            normalBackgroundImage.isHidden = false
            rejectingBackgroundImage.isHidden = true
            
        }
    }
}

