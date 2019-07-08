//
//  ProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class ProductListTableViewController: UITableViewController, DefaultInstanceFactory, UserSessionDepending {
    
    var userSession: UserSession!
    var sections: [Section] = [.runningBiddingIndicator, .biddingEndedIndicator, .productList, .bidList]

    @IBOutlet weak var countdownDescriptionLabel: UILabel!
    @IBOutlet weak var countDownView: CountDownClockView!
    private var refreshClock: UpdateClock!
    private var featureCheck: BiddingFeatureAccessCheckOperation?
    
    class func fromDefaultStoryboard() -> ProductListTableViewController {
        return UIStoryboard(name: "Auction", bundle: nil).instantiateViewController(withIdentifier: "ProductListTableViewController") as! ProductListTableViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProductListHeader.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.productListHeader)
        tableView.register(BiddingListHeader.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.biddingListHeader)
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        refreshClock = UpdateClock(preferredFrameRate: 15, onTick: {[weak self] in
            self?.refreshDynamicViews()
        })
        countdownDescriptionLabel.text = Localized.activity.countdown
    }
    
    private func refreshDynamicViews() {
        countDownView.tick()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .biddingEndedIndicator, .runningBiddingIndicator:
            return 1
        case .productList:
            return 10
        case .bidList:
            return 10
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .productList, .bidList:
            return 66
        case .biddingEndedIndicator, .runningBiddingIndicator:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: section.reuseID, for: indexPath)
        switch section {
        case .biddingEndedIndicator, .runningBiddingIndicator:
            configureBiddingStateIndicationCell(cell as! BiddingStateIndicationCell)
        case .bidList:
            configureBiddingCell(cell as! BiddingProductCell, at: indexPath)
        case .productList:
            configureProductCell(cell as! ProductOverviewCell, at: indexPath)
        }
        return cell
    }
    
    private func configureBiddingStateIndicationCell(_ cell: BiddingStateIndicationCell) {
        cell.descriptionTextView.delegate = self
    }
    
    private func configureProductCell(_ cell: ProductOverviewCell, at indexPath: IndexPath) {
        cell.unlockAction = {[weak self] in
            self?.checkAccessAndRunIfAllowed {
                self?.unlockProductIfAllowed(at: indexPath)
            }
        }
    }
    
    private func configureBiddingCell(_ cell: BiddingProductCell, at indexPath: IndexPath) {
        cell.bidAction = {[weak self] in
            self?.checkAccessAndRunIfAllowed {
                self?.bidProductIfAllowed(at: indexPath)
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sections[section] {
        case .biddingEndedIndicator, .runningBiddingIndicator:
            return 0
        case .productList:
            return ProductListHeader.height()
        case .bidList:
            return BiddingListHeader.height()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch sections[section] {
        case .biddingEndedIndicator, .runningBiddingIndicator:
            return nil
        case .productList:
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.productListHeader) as! ProductListHeader
            view.title = "All"
            view.showFilterAction = {[weak self] in
                self?.showFilterPicker()
            }
            return view
        case .bidList:
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.biddingListHeader)
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section].isSelectable
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .productList:
            performSegue(withIdentifier: SegueID.showProductDetail, sender: nil) //TODO: product
        case .bidList:
            performSegue(withIdentifier: SegueID.showProductDetail, sender: nil) //TODO: product
        default: break
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? ShippingInfoEditorViewController {
            vc.userSession = userSession
        }
    }

}

private extension ProductListTableViewController {
    func showShippingInfoEditor() {
        performSegue(withIdentifier: SegueID.showShippingInfoEditor, sender: nil)
    }
    
    func showFilterPicker() {
        
    }
    
    func checkAccessAndRunIfAllowed(_ completion: @escaping (()->())) {
        guard featureCheck == nil else { return }
        let op = BiddingFeatureAccessCheckOperation(userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleCheckResultAndRunIfAllowed(completion)
            }
        }
        featureCheck = op
        op.start()
    }
    
    func handleCheckResultAndRunIfAllowed(_ completion: @escaping (()->())) {
        let op = featureCheck!
        featureCheck = nil
        guard op.isAccessible else { return }
        completion()
    }
    
    func unlockProductIfAllowed(at indexPath: IndexPath) {
        performSegue(withIdentifier: SegueID.enterUnlockFlow, sender: nil)
    }
    
    func bidProductIfAllowed(at indexPath: IndexPath) {
        performSegue(withIdentifier: SegueID.enterBidFlow, sender: nil)
    }
}

private extension ProductListTableViewController {
    func setUpEmptyViewForEmptyRunningBidList() {
        let view = EmptyLotListView.fromDefaultNib()
        tableView.tableFooterView = view
    }
}

extension ProductListTableViewController {
    enum Section {
        case productList
        case bidList
        case runningBiddingIndicator
        case biddingEndedIndicator
        var reuseID: String {
            switch self {
            case .productList: return ReuseID.productOverviewCell
            case .bidList: return ReuseID.biddingItemCell
            case .runningBiddingIndicator: return ReuseID.runningBiddingCell
            case .biddingEndedIndicator: return ReuseID.biddingEndCell
            }
        }
        var isSelectable: Bool {
            switch self {
            case .productList, .bidList: return true
            case .runningBiddingIndicator, .biddingEndedIndicator: return false
            }
        }
    }
    
    struct ReuseID {
        static let runningBiddingCell = "runningBiddingCell"
        static let biddingEndCell = "biddingEndCell"
        static let biddingItemCell = "biddingItemCell"
        static let productOverviewCell = "productOverviewCell"
        static let productListHeader = "productListHeader"
        static let biddingListHeader = "biddingListHeader"
    }
    
    struct SegueID {
        static let showShippingInfoEditor = "showShippingInfoEditor"
        static let showProductDetail = "showProductDetail"
        static let enterBidFlow = "enterBidFlow"
        static let enterUnlockFlow = "enterUnlockFlow"
    }
}

extension ProductListTableViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.showShippingInfoEditor()
        }
        return false
    }
}

extension ProductListTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: Localized.phrases.commodities)
    }
}

class ProductOverviewCell: UITableViewCell {
    @IBOutlet weak var contentBackgroundView: UIView!
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
    var unlockAction: (()->())?
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateViewsForLockState()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    private func updateViewsForLockState() {
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        titleLabel.text = appearance.title
        titleLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }
    
    @IBAction func invokeUnlockAction(_ sender: UIButton) {
        unlockAction?()
    }
    
}

class LockAppearance {
    let title: String
    let color: UIColor
    init(title: String, color: UIColor) {
        self.title = title
        self.color = color
    }
    static let forLocked = LockAppearance(title: Localized.titles.unlock, color: ColorPalette.bidRed)
    static let forUnlocked = LockAppearance(title: Localized.titles.unlocked, color: ColorPalette.bidGreen)
}

class BiddingProductCell: UITableViewCell {
    @IBOutlet weak var contentBackgroundView: UIView!

    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var runningIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bidButton: UIButton!
    @IBOutlet weak var hundredLabel: UILabel!
    @IBOutlet weak var tensLabel: UILabel!
    @IBOutlet weak var digitLabel: UILabel!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet var leadIndicators: [UIButton]!
    var bidAction: (()->())?
    
    private let countdownTimeAttribute: [NSAttributedString.Key: Any] = [.kern: 3.5]
    var deadline = Date() {
        didSet {
            tick()
        }
    }
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        return TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
    }()

    let formatter: NumberFormatter = SharedNumberFormatters.clockComponent
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    func tick() {
        let i = deadline.timeIntervalSinceNow
        let comps = TimeIntervalComponents(extractor.extract(from: i))
        let min = formatter.string(for: comps.minutes) ?? "00"
        let sec = formatter.string(for: comps.seconds) ?? "00"
        var attr = countdownTimeAttribute
        attr[.foregroundColor] =  i < .minute ? ColorPalette.bidRed : ColorPalette.bidGreen
        countdownLabel.attributedText = NSAttributedString(string: min + ":" + sec, attributes: countdownTimeAttribute)
    }
    
    
    @IBAction func invokeBidAction(_ sender: UIButton) {
        bidAction?()
    }
}

class CountDownClockView: UIView {
    @IBOutlet weak var dayValueLabel: UILabel!
    @IBOutlet weak var hourValueLabel: UILabel!
    @IBOutlet weak var minuteValueLabel: UILabel!
    @IBOutlet weak var secondValueLabel: UILabel!
    
    var deadline = Date() {
        didSet {
            tick()
        }
    }
    private let attributes: [NSAttributedString.Key: Any] = [.kern: 4.67]
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        let hour = TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
        return TimeIntervalComponentExtractor(unitInterval: .day, next: hour)
    }()
    let formatter: NumberFormatter = SharedNumberFormatters.clockComponent
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func tick() {
        let comps = TimeIntervalComponents(extractor.extract(from: deadline.timeIntervalSinceNow))
        dayValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.days) ?? "00", attributes: attributes)
        hourValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.hours) ?? "00", attributes: attributes)
        minuteValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.minutes) ?? "00", attributes: attributes)
        secondValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.seconds) ?? "00", attributes: attributes)
    }
}

class BiddingStateIndicationCell: UITableViewCell {
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    fileprivate func prepareWinnerNotice() -> NSAttributedString {
        let text = String(format: Localized.messageFormats.winnerNotice, Localized.phrases.shippingInfo)
        let linkRange = (text as NSString).range(of: Localized.phrases.shippingInfo)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.addAttributes([.link : DeepLinks.shippingInfo], range: linkRange)
        return attrStr
    }
}

class RunningBiddingIndicationCell: BiddingStateIndicationCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        stateLabel.text = Localized.activity.bidding
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: Localized.messages.ongoingBidding + "\n", attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.append(prepareWinnerNotice())
        descriptionTextView.attributedText = attrStr
    }
}

class BiddingEndIndicationCell: BiddingStateIndicationCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        stateLabel.text = Localized.activity.biddingEnded
        descriptionTextView.attributedText = prepareWinnerNotice()
    }
}
