//
//  LoadingCell.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/1.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LoadingCell: UITableViewCell {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.startAnimating()
    }

}
