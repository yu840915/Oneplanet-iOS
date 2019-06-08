//
//  AuctionMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class AuctionMainViewController: ButtonBarPagerTabStripViewController {

    @IBOutlet weak var buttonBarContainer: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBarContainer.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [ProductListTableViewController.fromDefaultStoryboard(), BiddingLiveTableViewController.fromDefaultStoryboard()]
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

class ButtonBarContainer: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 40)
    }
}
