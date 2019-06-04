//
//  HotNavigationItemView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class HotNavigationItemView: UIView {
    class func defaultNib() -> UINib {
        return UINib(nibName: "HotNavigationItems", bundle: nil)
    }
    
    class func forNews() -> HotNavigationItemView {
        let view = defaultNib().instantiate(withOwner: nil, options: nil)[0] as! HotNavigationItemView
        view.titleLabel.text = Localized.feature.news
        return view
    }
    class func forEvents()  -> HotNavigationItemView {
        let view = defaultNib().instantiate(withOwner: nil, options: nil)[1] as! HotNavigationItemView
        view.titleLabel.text = Localized.feature.events
        return view
    }
    class func forAlien() -> HotNavigationItemView {
        let view = defaultNib().instantiate(withOwner: nil, options: nil)[2] as! HotNavigationItemView
        view.titleLabel.text = Localized.feature.alien
        return view
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 44, height: UIView.noIntrinsicMetric)
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    var action: (()->())?
    @IBAction func invokeAction(_ sender: UIButton) {
        action?()
    }
}
