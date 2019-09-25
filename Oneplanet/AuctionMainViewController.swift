//
//  AuctionMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import ModelBlocks

class AuctionMainViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {
    
    var userSession: UserSession! {
        didSet {
            shippingAddressHolder = ShippingAddressHolder(session: userSession)
            shippingAddressHolder.refreshIfAllowed()
        }
    }
    var shippingAddressHolder: ShippingAddressHolder!
    @IBOutlet weak var buttonBarContainer: UIView!
    private var shouldAddBadgeViews = true
    private var productListBadge: BadgeView!
    private var biddingProcessBadge: BadgeView!
    private var biddingFeatureCheckOperation: BiddingFeatureAccessCheckOperation?
    private var productListController: ProductListTableViewController!
    private var historyController: BiddingProcessTableViewController?
    private var initialQuery: String?
    private var updateClock: UpdateClock!
    private var needsRefresh = false
    private var isVisible = false

    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }
    
    override func viewDidLoad() {
        if userSession.isGuest {
            settings.style.selectedBarHeight = 0
        }
        super.viewDidLoad()
        updateClock = UpdateClock(onTick: {[weak self] in
            self?.updateHistoryBadgeIfNeeded()
        })
        buttonBarContainer.translatesAutoresizingMaskIntoConstraints = false
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
        
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        if let q = initialQuery {
            showCategoryList(with: q)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
        if needsRefresh {
            needsRefresh = false
            refresh()
        }
    }
    
    private func refresh() {
        productListController.categoryList?.reload()
        historyController?.refresh()
    }
    
    func setNeedsRefresh() {
        if isVisible {
            refresh()
        } else {
            needsRefresh = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpBadgeViewIfNeeded()
        checkBiddingFeatureOnEntryIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }

    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let productList = ProductListTableViewController.fromDefaultStoryboard()
        productList.setWantsTutorial()
        productList.shippingAddressHolder = shippingAddressHolder
        productListController = productList
        var controllers: [UIViewController] = [productList]
        if !userSession.isGuest {
            let vc = BiddingProcessTableViewController.fromDefaultStoryboard()
            vc.shippingAddressHolder = shippingAddressHolder
            historyController = vc
            controllers.append(vc)
        }
        controllers
            .compactMap{$0 as? UserSessionDepending}
            .forEach{$0.userSession = userSession}
        return controllers
    }
    
    private func updateHistoryBadgeIfNeeded() {
        if Preferences.shouldShowBadgeOnHistory.value == true {
            biddingProcessBadge.value = 1
        } else {
            biddingProcessBadge.value = 0
        }
    }
    
    func showCategoryList(with query: String) {
        guard isViewLoaded else {
            initialQuery = query
            return
        }
        productListController.updateCategoryList(with: query)
        moveTo(viewController: productListController)
    }
    
    func setWantsTutorial() {
        productListController?.setWantsTutorial()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

private extension AuctionMainViewController {
    func checkBiddingFeatureOnEntryIfNeeded() {
        guard biddingFeatureCheckOperation == nil
            && !userSession.isGuest else {
            return
        }
        let op = BiddingFeatureAccessCheckOperation(userSession: userSession)
        biddingFeatureCheckOperation = op
        op.start()
    }
    
    func setUpBadgeViewIfNeeded() {
        if biddingProcessBadge == nil {
            biddingProcessBadge = prepareBadge(for: buttonBarView.visibleCells.first as! ButtonBarViewCell)
        }
        if productListBadge == nil {
            productListBadge = prepareBadge(for: buttonBarView.visibleCells.last as! ButtonBarViewCell)
        }
    }
    
    func prepareBadge(for cell: ButtonBarViewCell) -> BadgeView {
        let badge = BadgeView.fromDefaultNib()
        cell.addSubview(badge)
        let label = cell.label!
        cell.addConstraint(NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: badge, attribute: .centerX, multiplier: 1, constant: -5))
        cell.addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: badge, attribute: .centerY, multiplier: 1, constant: 0))
        return badge
    }
    
    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        if userSession.isGuest {
            newCell?.label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        } else {
            newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
        }
    }
}

class ButtonBarContainer: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 40)
    }
}

class PagerStyleConfigurer {
    func configure(_ controller:  ButtonBarPagerTabStripViewController) {
        controller.settings.style.selectedBarBackgroundColor = .white
        controller.settings.style.buttonBarItemBackgroundColor = .clear
        controller.settings.style.buttonBarItemsShouldFillAvailableWidth = true
        controller.settings.style.buttonBarBackgroundColor = .clear
        controller.settings.style.buttonBarItemTitleColor = Style.normal.titleColor
        controller.settings.style.buttonBarItemFont = Style.normal.font
        controller.settings.style.selectedBarHeight = 1
        controller.settings.style.buttonBarItemLeftRightMargin = 0
        controller.pagerBehaviour = .progressive(skipIntermediateViewControllers: true, elasticIndicatorLimit: false)
    }
    
    class Style {
        let titleColor: UIColor
        let font: UIFont
        init(titleColor: UIColor, font: UIFont) {
            self.titleColor = titleColor
            self.font = font
        }
        static let normal = Style(titleColor: ColorPalette.defaultPlaceholder, font: .systemFont(ofSize: 12))
        static let highlighted = Style(titleColor: ColorPalette.defaultText, font: .systemFont(ofSize: 12, weight: .semibold))
    }
}

class ShippingAddressHolder {
    private(set) var shippingAddress: ShippingAddress?
    let session: UserSession
    private var getAddressOperation: GetShippingAddressOperation? {
        didSet {
            updateHandlers.invokeEach{$0()}
        }
    }
    let updateHandlers = MulticastCallbackNode<()->()>()
    
    init(session: UserSession) {
        self.session = session
    }
    
    func refreshIfAllowed() {
        guard !session.isGuest && getAddressOperation == nil else { return }
        let op = GetShippingAddressOperation(session: session)
        op.completionBlock = {[weak self] in
            self?.didRefresh()
        }
        getAddressOperation = op
        op.start()
    }
    
    private func didRefresh() {
        let op = getAddressOperation!
        getAddressOperation = nil
        if op.success == true {
            shippingAddress = op.shippingAddress
        }
    }
}
