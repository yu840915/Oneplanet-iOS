//
//  BiddingProcessTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import Kingfisher

class BiddingProcessTableViewController: UITableViewController, DefaultInstanceFactory {

    var sections: [Section] = [.shippingInfoPrompt, .items]
    class func fromDefaultStoryboard() -> BiddingProcessTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "BiddingLiveTableViewController") as! BiddingProcessTableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BiddingProcessHeader.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.biddingItemHeader)
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
        switch section {
        case .shippingInfo, .shippingInfoPrompt:
            prepareShippingInfoCell(cell as! ShippingInfoCell)
        case .items:
            prepareItemCell(cell as! BidOutcomeCell, at: indexPath)
        }
        return cell
    }
    
    private func prepareShippingInfoCell(_ cell: ShippingInfoCell) {
        cell.action = {[weak self] in
            self?.showShippingInfoEditor()
        }
    }
    
    private func prepareItemCell(_ cell: BidOutcomeCell, at indexPath: IndexPath) {
        cell.detailAction = {[weak self] in
            self?.showShippingStatusDetail()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            return 0
        case .items:
            return BiddingProcessHeader.height()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            return nil
        case .items:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.biddingItemHeader)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            return 10
        case .items:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            let view = UIView()
            return view
        case .items:
            return nil
        }

    }


    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

fileprivate extension BiddingProcessTableViewController {
    func showShippingInfoEditor() {
    }
    
    func showShippingStatusDetail() {
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
        static let biddingItemHeader = "biddingItemHeader"
    }
}

extension BiddingProcessTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: Localized.phrases.biddingProcess)
    }
}

protocol BidOutcomeOverviewDisplayable: AnyObject {
    var hasWon: Bool {get}
    var productThumnail: WebImageInfo? {get}
    var productName: String {get}
    var localizedShippingState: String? {get}
}

class BidOutcomeCell: UITableViewCell {
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
    
    func updateViews(with ds: BidOutcomeOverviewDisplayable) {
        previewImageView.kf.setImage(with: ds.productThumnail?.url)
        titleLabel.text = ds.productName
        outcomIndicator.backgroundColor = ds.hasWon ? ColorPalette.bidGreen : ColorPalette.bidRed
        if let state = ds.localizedShippingState {
            stateLabel.text = state
        } else {
            stateLabel.text = ds.hasWon ? "Miss" : "Preparing"
        }
    }
}


class ShippingInfoCell: UITableViewCell {
    var action: (()->())?
}

class EmptyShippingInfoCell: ShippingInfoCell {
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

class ConfiguredShippingInfoCell: ShippingInfoCell {
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
