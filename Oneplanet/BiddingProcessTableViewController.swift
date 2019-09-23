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
    var shippingAddressHolder: ShippingAddressHolder!
    var bidOutcomeHistory: BidOutcomeHistory!
    var sections: [Section] = [.shippingInfoPrompt, .items]
    var products: [BidProductOverview] = []
    private var handles: [Any]?
    class func fromDefaultStoryboard() -> BiddingProcessTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "BiddingLiveTableViewController") as! BiddingProcessTableViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BiddingProcessHeader.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.biddingItemHeader)
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareHistory()
        if shippingAddressHolder.shippingAddress != nil {
            sections = [.shippingInfo, .items]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Preferences.shouldShowBadgeOnHistory.value = false
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
        case .shippingInfoPrompt:
            prepareShippingInfoCell(cell as! ShippingInfoCell)
        case .shippingInfo:
            prepareConfiguredShippingInfoCell(cell as! ConfiguredShippingInfoCell)
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

    private func prepareConfiguredShippingInfoCell(_ cell: ConfiguredShippingInfoCell) {
        cell.action = {[weak self] in
            self?.showShippingInfoEditor()
        }
        if let address = shippingAddressHolder.shippingAddress {
            cell.addressLabel.text = formatAddress(from: address)
        } else {
            cell.addressLabel.text = nil
        }
    }
    
    private func formatAddress(from addr: ShippingAddress) -> String {
        var value = ""
        var newline = false
        if let first = addr.firstName, !first.isEmpty {
            value += first
            newline = true
        }
        if let last = addr.lastName, !last.isEmpty {
            if newline {
                value += " "
            }
            value += "***"
            newline = true
        }
        if let phone = addr.phone, !phone.isEmpty {
            if newline {
                value += "\n"
            }
            if let code = addr.country, let country = PhoneNumberBuilder(countryCode: nil).countries.first(where: {$0.isoCountryCode.lowercased() == code.lowercased()}) {
                
                value += "(\(country.cellPhoneContryCode))"
            }
            if phone.count <= 3 {
                value += Array(repeating: "*", count: phone.count).joined()
            } else {
                let num = (phone.count - 3) / 2
                let extra = (phone.count - 3) % 2
                let prefix = phone.prefix(num + extra)
                let suffix = phone.suffix(num)
                value += prefix + "***" + suffix
            }
            newline = true
        }
        if let addr1 = addr.addressLine1, !addr1.isEmpty {
            if newline {
                value += "\n"
            }
            value += addr1
            newline = true
        }
        if let addr2 = addr.addressLine2, !addr2.isEmpty {
            if newline {
                value += "\n"
            }
            value += addr2
        }
        return value
    }

    private func prepareItemCell(_ cell: BidOutcomeCell, at indexPath: IndexPath) {
        let product = products[indexPath.row]
        cell.updateViews(with: product)
        cell.detailAction = {[weak self] in
            self?.showShippingStatusDetailForProduct(at: indexPath)
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
        if let nav = segue.destination as? UINavigationController {
            if let vc = nav.viewControllers.first as? ShippingInfoEditorViewController {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? ShippingInfoEditorViewController {
                vc.shippingAddressHolder = shippingAddressHolder
            }
        }
    }

}

fileprivate extension BiddingProcessTableViewController {
    func showShippingInfoEditor() {
        performSegue(withIdentifier: SegueID.showShippingInfoEditor, sender: nil)
    }
    
    func showShippingStatusDetailForProduct(at indexPath: IndexPath) {
        guard let states = products[indexPath.row].shippingStates,
            let number = states.trackingNumber else {
                return
        }
        UIPasteboard.general.string = number
        if let url = states.trackingURL {
            let alert = UIAlertController(title: Localized.phrases.viewShippingStatus, message: Localized.messages.copiedOrderNumber, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.go, style: .default, handler: { (_) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }))
            alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            Toast.show(with: String(format: Localized.messages.copiedOrderNumber))
        }
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
        handles.append(shippingAddressHolder.updateHandlers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateViewsForShippingAddressChange()
            }
        })
        bidOutcomeHistory = history
        self.handles = handles
        history.reload()
    }
    
    func updateViewsForShippingAddressChange() {
        if shippingAddressHolder.shippingAddress != nil {
            sections = [.shippingInfo, .items]
        } else {
            sections = [.shippingInfoPrompt, .items]
        }
        tableView.reloadData()
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
    
    func updateViews(with product: BidProductOverview) {
        previewImageView.kf.setImage(with: product.cover?.url)
        titleLabel.text = product.displayName
        if let shippingStates = product.shippingStates {
            outcomIndicator.backgroundColor = ColorPalette.bidGreen

            stateLabel.isHidden = false
            stateLabel.text = shippingStates.isShipped ? Localized.titles.bidStateShipping : Localized.titles.bidStateToShip
            if let num = shippingStates.trackingNumber, !num.isEmpty {
                inspectButton.isHidden = false
            } else {
                inspectButton.isHidden = true
            }
        } else {
            outcomIndicator.backgroundColor = ColorPalette.bidRed
            inspectButton.isHidden = true
            stateLabel.text = Localized.titles.bidStateLose
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
