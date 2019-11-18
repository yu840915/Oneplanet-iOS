//
//  PickerConfirmButtonFooter.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PickerConfirmButtonFooter: UITableViewHeaderFooterView {
    class func defaultNib() -> UINib {
        return UINib(nibName: "PickerConfirmButtonFooter", bundle: nil)
    }
    
    var commitAction: (()->())?
    @IBOutlet weak var commitButton: UIButton!
    
    @IBAction func commit(_ sender: UIButton) {
        commitAction?()
    }
    
}
