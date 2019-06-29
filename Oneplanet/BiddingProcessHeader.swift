//
//  BiddingProcessHeader.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/13.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BiddingProcessHeader: UITableViewHeaderFooterView {
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var outcomeLabel: UILabel!
    
    class func defaultNib() -> UINib {
        return UINib(nibName: "BiddingProcessHeader", bundle: nil)
    }
    class func height() -> CGFloat {
        return 22.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        productNameLabel.text = Localized.phrases.productName
        outcomeLabel.text = Localized.phrases.bidOutcome
    }
}
