//
//  AuctionMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/8.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class AuctionMainViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {
    
    var userSession: UserSession!
    @IBOutlet weak var buttonBarContainer: UIView!
    private var shouldAddBadgeViews = true
    private var productListBadge: BadgeView!
    private var biddingProcessBadge: BadgeView!
    private var biddingFeatureCheckOperation: BiddingFeatureAccessCheckOperation?
    private var productListController: ProductListTableViewController!
    private var initialQuery: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBarContainer.translatesAutoresizingMaskIntoConstraints = false
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        if let q = initialQuery {
            showCategoryList(with: q)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpBadgeViewIfNeeded()
        checkBiddingFeatureOnEntryIfNeeded()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let productList = ProductListTableViewController.fromDefaultStoryboard()
        productListController = productList
        let controllers = [productList, BiddingProcessTableViewController.fromDefaultStoryboard()]
        controllers
            .compactMap{$0 as? UserSessionDepending}
            .forEach{$0.userSession = userSession}
        return controllers
    }
    
    func showCategoryList(with query: String) {
        guard isViewLoaded else {
            initialQuery = query
            return
        }
        productListController.updateCategoryList(with: query)
        moveTo(viewController: productListController)
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
        cell.addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: badge, attribute: .centerY, multiplier: 1, constant: 2))
        return badge
    }
    
    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
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
