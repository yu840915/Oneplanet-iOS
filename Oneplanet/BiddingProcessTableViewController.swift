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

class BiddingProcessTableViewController: UITableViewController, DefaultInstanceFactory, UserSessionDepending {
    
    var userSession: UserSession!
    var bidOutcomeHistory: BidOutcomeHistory!
    var sections: [Section] = [.shippingInfoPrompt, .items]
    var products: [ProductOverview] = []
    private var updateClock: UpdateClock!
    private var handles: [Any]?
    class func fromDefaultStoryboard() -> BiddingProcessTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "BiddingLiveTableViewController") as! BiddingProcessTableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BiddingProcessHeader.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.biddingItemHeader)
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareHistory()
        updateClock = UpdateClock(onTick: {[weak self] in
            self?.updateItemCells()
        })
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
            return products.count
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
        let product = products[indexPath.row]
        cell.updateViews(with: product)
        cell.updateViews(with: userSession.bidProcessManager.process(for: product))
        cell.detailAction = {[weak self] in
            self?.showShippingStatusDetail()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .shippingInfo, .shippingInfoPrompt:
            return 0.1
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
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? ShippingInfoEditorViewController {
            vc.userSession = userSession
        }
    }

}

fileprivate extension BiddingProcessTableViewController {
    func updateItemCells() {
        guard let indeices = tableView.indexPathsForVisibleRows?.filter({sections[$0.section] == .items}) else {
            return
        }
        indeices.forEach{
            updateItemCell(at: $0)
        }
    }
    
    func updateItemCell(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? BidOutcomeCell else {
            return
        }
        cell.updateViews(with: userSession.bidProcessManager.process(for: products[indexPath.row]))
    }
    
    func showShippingInfoEditor() {
        performSegue(withIdentifier: SegueID.showShippingInfoEditor, sender: nil)
    }
    
    func showShippingStatusDetail() {
    }
    
    func prepareHistory() {
        let history = BidOutcomeHistory(session: userSession)
        var handles: [Any] = []
        handles.append(history.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleHistoryUpdate()
            }
        })
        handles.append(history.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        bidOutcomeHistory = history
        self.handles = handles
        history.reload()
    }
    
    func handleHistoryUpdate() {
        products = bidOutcomeHistory.items
        updateBackground(with: nil)
        tableView.reloadData()
    }
    
    func handleFetchFailure(with error: Error?) {
        updateBackground(with: error)
    }
    
    func updateBackground(with error: Error? = nil) {
        if !products.isEmpty {
            tableView.tableFooterView = UIView()
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            view.titleLabel.text = Localized.emptyMessages.unlocked
            view.detailLabel.text = Localized.emptyMessages.unlockedDetail
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            view.frame = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 300))
            tableView.tableFooterView = view
        }
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

    struct SegueID {
        static let showShippingInfoEditor = "showShippingInfoEditor"
    }
}

extension BiddingProcessTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: Localized.phrases.biddingProcess)
    }
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
    
    func updateViews(with process: ProductBidProcess) {
        outcomIndicator.backgroundColor = process.isWinning ? ColorPalette.bidGreen : ColorPalette.bidRed
        inspectButton.isHidden = !process.isWinning
    }
    
    func updateViews(with product: ProductOverview) {
        previewImageView.kf.setImage(with: product.cover?.url)
        titleLabel.text = product.displayName
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
