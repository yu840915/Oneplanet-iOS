//
//  BadgeView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BadgeView: UIView, DefaultViewInstanceFactory {
    @IBOutlet weak var titleLabel: UILabel!
    var value: Int = 0 {
        didSet {
            if oldValue != value {
                updateViewsForValue()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = frame.height / 2
        updateViewsForValue()
    }
    
    private func updateViewsForValue() {
        isHidden = value == 0
        titleLabel.text = SharedNumberFormatters.integer.string(for: value)
    }
    
    class func fromDefaultNib() -> BadgeView {
        return UINib(nibName: "BadgeView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! BadgeView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.height / 2
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 16)
    }
}
