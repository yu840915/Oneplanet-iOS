//
//  ProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class ProductListTableViewController: UITableViewController, DefaultInstanceFactory {
    
    class func fromDefaultStoryboard() -> ProductListTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "ProductListTableViewController") as! ProductListTableViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ProductListTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Commodities")
    }
}

class ProductOverviewCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    var isLocked = true {
        didSet {
            if oldValue != isLocked {
                updateViewsForLockState()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateViewsForLockState()
    }
    
    private func updateViewsForLockState() {
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        titleLabel.text = appearance.title
        titleLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }
}

extension ProductOverviewCell {
    class LockAppearance {
        let title: String
        let color: UIColor
        init(title: String, color: UIColor) {
            self.title = title
            self.color = color
        }
        static let forLocked = LockAppearance(title: Localized.titles.unlock, color: ColorPalette.lockRed)
        static let forUnlocked = LockAppearance(title: Localized.titles.unlocked, color: ColorPalette.lockGreen)
    }
}

class BiddingProductCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!

}
