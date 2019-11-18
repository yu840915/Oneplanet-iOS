//
//  EmptyLotListView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class EmptyLotListView: UIView, DefaultViewInstanceFactory {
    
    class func fromDefaultNib() -> EmptyLotListView {
        return UINib(nibName: "EmptyLotListView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EmptyLotListView
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.emptyMessages.unlockedLotsTitle
        detailLabel.text = Localized.emptyMessages.unlockedLotsMessage
    }
}
