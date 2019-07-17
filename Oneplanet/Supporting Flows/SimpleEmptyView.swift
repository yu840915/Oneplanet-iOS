//
//  SimpleEmptyView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SimpleEmptyView: UIView, DefaultViewInstanceFactory {
    
    static func fromDefaultNib() -> SimpleEmptyView {
        return UINib(nibName: "SimpleEmptyView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SimpleEmptyView
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
}
