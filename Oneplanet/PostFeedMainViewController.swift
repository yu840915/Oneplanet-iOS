//
//  PostFeedMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/25.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostFeedMainViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {

    var userSession: UserSession!
    @IBOutlet weak var buttonBarContainer: UIView!
    private var pages: [PostFeedTableViewController] = []
    private var postPublishHandle: Any?
    
    override func viewDidLoad() {
        settings.style.selectedBarHeight = 0
        super.viewDidLoad()
        buttonBarContainer.translatesAutoresizingMaskIntoConstraints = false
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
        postPublishHandle = userSession.postPublishObservers.add({[weak self] (_) in
            self?.setNeedsRefresh()
        })
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let latest = PostFeedTableViewController.fromDefaultStoryboard()
        latest.title = Localized.phrases.latestPosts
        latest.userSession = userSession
        latest.postList = PostList.postList(with: userSession)
//        let promoted = PostFeedTableViewController.fromDefaultStoryboard()
//        promoted.userSession = userSession
//        promoted.title = Localized.phrases.bestPosts
//        promoted.postList = PostList.promotedPostList(with: userSession)
        pages = [latest]
        return pages
    }
    
    func setNeedsRefresh() {
        pages.forEach{ $0.setNeedsRefresh() }
    }
    
}

extension ButtonBarPagerTabStripViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        if let vc = viewControllers[currentIndex] as? ScrollToTopHandler {
            vc.setWantsScrollToTop()
        }
    }
}

private extension PostFeedMainViewController {
    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        newCell?.label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
//        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
//        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
//        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
//        newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
    }
}

