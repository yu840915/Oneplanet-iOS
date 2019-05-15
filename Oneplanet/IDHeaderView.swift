//
//  IDHeaderView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class IDHeaderView: UIView, DefaultViewInstanceFactory {
    
    class func fromDefaultNib() -> IDHeaderView {
        return UINib(nibName: "IDHeaderView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! IDHeaderView
    }
    
    var copyAction: (()->())?
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var copyButton: UIButton!

    @IBAction func invokeCopyAction(_ sender: UIButton) {
        copyAction?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        translatesAutoresizingMaskIntoConstraints = false
        copyButton.setTitle(Localized.phrases.copyID, for: .normal)
        idLabel.text = "a124fk8ew0"
    }
}
