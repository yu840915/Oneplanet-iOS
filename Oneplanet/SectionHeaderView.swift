//
//  SectionHeaderView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SectionHeaderView: UITableViewHeaderFooterView, DefaultViewInstanceFactory {
    class func defaultNib() -> UINib {
        return UINib(nibName: "SectionHeaderView", bundle: nil)
    }
    class func fromDefaultNib() -> SectionHeaderView {
        return defaultNib().instantiate(withOwner: nil, options: nil).first as! SectionHeaderView
    }
    
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
}
