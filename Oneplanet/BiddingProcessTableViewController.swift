//
//  BiddingProcessTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class BiddingProcessTableViewController: UITableViewController, DefaultInstanceFactory {

    var sections: [Section] = [.shippingInfoPrompt, .items]
    class func fromDefaultStoryboard() -> BiddingProcessTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "BiddingLiveTableViewController") as! BiddingProcessTableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            return 1
        case .items:
            return 10
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .shippingInfoPrompt, .items:
            return 60
        case .shippingInfo:
            return UITableView.automaticDimension
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: section.reuseID, for: indexPath)
        return cell
    }
    
    private func showShippingInfoEditor() {
        
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

extension BiddingProcessTableViewController {
    enum Section {
        case shippingInfoPrompt
        case shippingInfo
        case items
        var reuseID: String {
            switch self {
            case .items: return ReuseID.biddingItemResultCell
            case .shippingInfo: return ReuseID.shippingInfoCell
            case .shippingInfoPrompt: return ReuseID.shippingInfoPromptCell
            }
        }
    }
    
    struct ReuseID {
        static let shippingInfoPromptCell = "shippingInfoPromptCell"
        static let shippingInfoCell = "shippingInfoCell"
        static let biddingItemResultCell = "biddingItemResultCell"
    }
}

extension BiddingProcessTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Bidding Process")
    }
}

class BidResultCell: UITableViewCell {
    var detailAction: (()->())?
    @IBOutlet weak var outcomIndicator: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var inspectButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        inspectButton.setTitle(Localized.phrases.viewShippingStatus, for: .normal)
    }
    
    @IBAction func invokeDetailAction(_ sender: Any) {
        detailAction?()
    }
}

class ShippingInfoPromptCell: UITableViewCell {
    var action: (()->())?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.phrases.shippingInfo
        actionButton.setTitle(Localized.phrases.createShippingInfo, for: .normal)
    }
    
    @IBAction func invokeAction(_ sender: UIButton) {
        action?()
    }
}

class ShippingInfoCell: UITableViewCell {
    var action: (()->())?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.phrases.shippingInfo
        actionButton.setTitle(Localized.phrases.editProfile, for: .normal)
    }

    @IBAction func invokeAction(_ sender: UIButton) {
        action?()
    }
}
