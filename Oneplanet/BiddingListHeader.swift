//
//  BiddingListHeader.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/13.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BiddingListHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var productLabel: UILabel!
    @IBOutlet weak var bidCountLabel: UILabel!
    @IBOutlet weak var leaderLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var bidLabel: UILabel!

    class func defaultNib() -> UINib {
        return UINib(nibName: "BiddingListHeader", bundle: nil)
    }
    class func height() -> CGFloat {
        return 22.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        productLabel.text = Localized.phrases.bidLot
        bidCountLabel.text = Localized.phrases.bidCount
        leaderLabel.text = Localized.phrases.bidLeader
        countdownLabel.text = Localized.phrases.countdown
        bidLabel.text = Localized.titles.bid
    }
}
