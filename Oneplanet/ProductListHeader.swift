//
//  ProductListHeader.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/13.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProductListHeader: UITableViewHeaderFooterView {
    class func defaultNib() -> UINib {
        return UINib(nibName: "ProductListHeader", bundle: nil)
    }
    class func height() -> CGFloat {
        return 31.0
    }
    
    var title: String = "" {
        didSet {
            if oldValue != title {
                updateForTitle()
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    var showFilterAction: (()->())?
    @IBOutlet weak var filterButton: UIButton!
    
    @IBAction func showFilter(_ sender: UIButton) {
        showFilterAction?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.titles.filter
    }
    
    private func updateForTitle() {
        let attrStr = NSMutableAttributedString(string: title + " ", attributes: [.foregroundColor : ColorPalette.defaultText])
        attrStr.append(NSAttributedString(attachment: TextAttachmentFactory.shared.arrowDown()))
        filterButton.setAttributedTitle(attrStr, for: .normal)
    }
}
