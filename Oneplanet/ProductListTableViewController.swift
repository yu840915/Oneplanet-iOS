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
    var bidPhaseIndicator: BidPhaseIndicator {
        return userSession.bidPhaseIndicator
    }
    var sections: [Section] = [.runningBiddingIndicator, .biddingEndedIndicator, .productList, .bidList]
    private var wantsTutorial = false
    private var tutorialPlan: TutorialPlan?

    @IBOutlet weak var countdownDescriptionLabel: UILabel!
    @IBOutlet weak var countDownView: CountDownClockView!
    private var refreshClock: UpdateClock!
    private var featureCheck: BiddingFeatureAccessCheckOperation?
    private(set) var categoryList: CategoryList?
    private var myLotList: MyLotList?
    private var productOverviews: [ProductOverview] = []
    private var lots: [ProductOverview] = []
    private var bidProcesses: [BidProcess] = []
    private var categoryListHandles: [Any]?
    private var lotListDidUpdateHandles: [Any]?
    private var bidPhaseUpdateHandle: Any?
    
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
        prepareListForBidPhase()
        bidPhaseUpdateHandle = bidPhaseIndicator.updateObservers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.prepareListForBidPhase()
                self?.updateViewsForBidPhase()
            }
        }
        updateViewsForBidPhase()
    }
    
    private func prepareListForBidPhase() {
        if userSession.bidPhaseIndicator.biddingHasStarted {
            if myLotList == nil {
                prepareLotList()
            }
            categoryList = nil
        } else {
            if categoryList == nil {
                updateCategoryList(with: "other")
            }
            myLotList = nil
        }
    }
    
    private func updateViewsForBidPhase() {
        switch bidPhaseIndicator.phase {
        case .unlock:
            countdownDescriptionLabel.text = Localized.activity.countdown
            countDownView.deadline = userSession.bidPhaseIndicator.startDate
        case .running, .spectator:
            countdownDescriptionLabel.text = Localized.activity.bidding
        case .ended:
            countdownDescriptionLabel.text = nil
        }
        updateSectionsForBidPhase()
    }
    private func updateSectionsForBidPhase() {
        var values: [Section] = []
        if bidPhaseIndicator.biddingHasStarted {
            switch bidPhaseIndicator.phase {
            case .ended: values.append(.biddingEndedIndicator)
            case .spectator: values.append(.runningBiddingIndicator)
            default: break
            }
            values.append(.bidList)
        } else {
            values = [.productList]
        }
        sections = values
        tableView.reloadData()
    }
    
    func updateCategoryList(with query: String) {
        if query == categoryList?.query {
            return
        }
        let list = CategoryList(session: userSession, query: query)
        var handles: [Any] = []
        handles.append(list.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleCategoryListUpdate()
            }
        })
        handles.append(list.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleCategoryListUpdateFailure(with: error)
            }
        }))
        categoryListHandles = handles
        categoryList = list
        list.reload()
    }
    
    func setWantsTutorial() {
        wantsTutorial = true
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
            return productOverviews.count
        case .bidList:
            return lots.count
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
        let product = productOverviews[indexPath.row]
        cell.updateViews(with: product)
        cell.isLocked = userSession.lotList.isLocked(product)

    }
    
    private func configureBiddingCell(_ cell: BiddingProductCell, at indexPath: IndexPath) {
        cell.updateViews(with: lots[indexPath.row])
        let process = bidProcesses[indexPath.row]
        process.leadFetcher?.initializeIfNeeded()
        cell.updateViews(with: process)
        cell.bidAction = {[weak self] in
            self?.checkAccessAndRunIfAllowed {
                self?.bidProductIfAllowed(at: indexPath)
            }
        }
        cell.showDetailAction = {[weak self] in
            self?.showProductDetailForCell(at: indexPath)
        }
        cell.showProfileAction = {[weak self] in
            self?.showLeadUserForBid(at: indexPath)
        }
    }
    
    private func showProductDetailForCell(at indexPath: IndexPath) {
        if sections[indexPath.section] == .productList {
            performSegue(withIdentifier: SegueID.showProductDetail, sender: productOverviews[indexPath.row])
        } else if sections[indexPath.section] == .bidList {
            performSegue(withIdentifier: SegueID.showProductDetail, sender: lots[indexPath.row])
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
            if categoryList?.isUnlockLlist == true {
                view.title = Localized.phrases.categoryUnlocked
            } else {
                view.title = categoryList?.query ?? "–"
            }
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
            showProductDetailForCell(at: indexPath)
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .productList:
            let isLast = indexPath.row == (productOverviews.count - 1)
            if isLast {
                categoryList?.loadMoreIfAllowed()
            }
        case .bidList:
            let isLast = indexPath.row == (lots.count - 1)
            if isLast {
                myLotList?.loadMoreIfAllowed()
            }
        default: break
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        switch sections[section] {
        case .bidList: break
        case .productList: break
        default: break
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? ProductDetailViewController {
            vc.productQuery = (sender as! ProductOverview).name
        }
        if let vc = segue.destination as? UnlockFlowViewController {
            vc.product = (sender as! ProductOverview)
        }
        if let vc = segue.destination as? BidFlowViewController {
            let product = (sender as! ProductOverview)
            vc.product = product
            vc.bidProcess = userSession.bidEventProcessManager.process(for: product)
        }

        if let nav = segue.destination as? UINavigationController {
            if let vc = nav.viewControllers.first as? UserSessionDepending {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? ProductFilterPickerTableViewController {
                vc.currentCategoryName = categoryList?.query
                vc.didSelectItem = {[weak self] item in
                    let i = item as! CategoryNameViewModel
                    self?.updateCategoryList(with: i.categoryName.name)
                }
            }
            if let vc = nav.viewControllers.first as? UserProfileViewController {
                vc.profile = (sender as! User)
            }
        }
    }
}

private extension ProductListTableViewController {
    func refreshDynamicViews() {
        countDownView.tick()
        if bidPhaseIndicator.biddingHasStarted {
            updateBidCells()
        } else {
            updateProductCells()
        }
    }
    
    func updateBidCells() {
        guard let indeices = tableView.indexPathsForVisibleRows?.filter({sections[$0.section] == .bidList}) else {
            return
        }
        indeices.forEach{
            updateBidCell(at: $0)
        }
    }
    
    func updateBidCell(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? BiddingProductCell else {
            return
        }
        cell.updateViews(with: bidProcesses[indexPath.row])
    }
    
    func updateProductCells() {
        guard let indeices = tableView.indexPathsForVisibleRows?.filter({sections[$0.section] == .productList}) else {
            return
        }
        indeices.forEach{
            updateProductCell(at: $0)
        }
    }
    
    func updateProductCell(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ProductOverviewCell else {
            return
        }
        cell.isLocked = userSession.lotList.isLocked(productOverviews[indexPath.row])
    }

    
    func showProfile(for user: User) {
        performSegue(withIdentifier: SegueID.showProfile, sender: user)
    }

    func showShippingInfoEditor() {
        performSegue(withIdentifier: SegueID.showShippingInfoEditor, sender: nil)
    }
    
    func showFilterPicker() {
        performSegue(withIdentifier: SegueID.showFilter, sender: nil)
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
        performSegue(withIdentifier: SegueID.enterUnlockFlow, sender: productOverviews[indexPath.row])
    }
    
    func bidProductIfAllowed(at indexPath: IndexPath) {
        performSegue(withIdentifier: SegueID.enterBidFlow, sender: lots[indexPath.row])
    }
    
    func showLeadUserForBid(at indexPath: IndexPath) {
        guard let user = bidProcesses[indexPath.row].lead else {
            return
        }
        performSegue(withIdentifier: SegueID.showProfile, sender: user)
    }
}

private extension ProductListTableViewController {
    func handleCategoryListUpdate() {
        guard let list = categoryList else {return}
        productOverviews = list.items
        updateBackgroundForCategoryList(with: nil)
        tableView.reloadData()
    }
    
    func handleCategoryListUpdateFailure(with error: Error?) {
        updateBackgroundForCategoryList(with: error)
    }

    func updateBackgroundForCategoryList(with error: Error? = nil) {
        if !productOverviews.isEmpty {
            tableView.tableFooterView = UIView()
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            if categoryList?.isUnlockLlist == true {
                view.titleLabel.text = Localized.emptyMessages.unlocked
                view.detailLabel.text = Localized.emptyMessages.unlockedDetail
            } else {
                view.titleLabel.text = Localized.emptyMessages.generic
                if let error = error {
                    view.detailLabel.text = error.localizedDescription
                }
            }
            view.frame = CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 300))
            tableView.tableFooterView = view
        }
    }

    func prepareLotList() {
        let list = userSession.lotList!
        var handles: [Any] = []
        handles.append(list.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.lotListDidUpdate()
            }
        })
        handles.append(list.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.updateBackgroundForLotList(with: error)
            }
        }))
        lotListDidUpdateHandles = handles
        list.reload()
        myLotList = list
    }
    
    func lotListDidUpdate() {
        lots = myLotList!.items
        bidProcesses = lots.map{userSession.bidEventProcessManager.process(for: $0)}
        updateBackgroundForLotList(with: nil)
        tableView.reloadData()
    }
    
    func updateBackgroundForLotList(with error: Error? = nil) {
        if !lots.isEmpty {
            tableView.tableFooterView = UIView()
        } else {
            let view = EmptyLotListView.fromDefaultNib()
            view.titleLabel.text = Localized.emptyMessages.unlockedLotsTitle
            if bidPhaseIndicator.phase == .ended {
                view.detailLabel.text = Localized.messages.lotClosedDescription
            } else {
                view.titleLabel.text = Localized.emptyMessages.unlockedLotsMessage
            }
            tableView.tableFooterView = view
        }
    }
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
            case .productList: return true
            case .runningBiddingIndicator, .biddingEndedIndicator, .bidList: return false
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
        static let showFilter = "showFilter"
        static let showProfile = "showProfile"
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

extension ProductListTableViewController {
    struct TutorialPlan {
        let unlock: Bool
        let waitForBid: Bool
        let bid: Bool
    }
}
