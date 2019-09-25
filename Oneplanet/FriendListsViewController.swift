//
//  FriendListsViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class FriendListsViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var profile: UserProfileDisplayable!
    var preselectedTab: Tab = .follower
    private var shouldUpdateForPreselection = true
    var followerList: UserList!
    var followingList: UserList!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = profile.nickname
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController,
            nav.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localized.titles.done, style: .done, target: self, action: #selector(exit(_:)))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldUpdateForPreselection {
            shouldUpdateForPreselection = false
            moveToViewController(at: preselectedTab.rawValue, animated: false)
        }
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let follower = FollowingListTableViewController.fromDefaultStoryboard()
        follower.userList = followerList
        follower.userSession = userSession
        follower.configuration = .forFollowerList
        follower.title = Localized.titles.followers
        let following = FollowingListTableViewController.fromDefaultStoryboard()
        following.userList = followingList
        following.title = Localized.titles.followings
        following.configuration = .forFollowingList
        following.userSession = userSession
        return [follower, following]
    }

    @IBAction func exit(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
    }
   
}

extension FriendListsViewController {
    enum Tab: Int {
        case follower = 0
        case following = 1
    }
}

class FriendshipOverviewModel: UserOverviewDisplayable {
    var avatar: WebImageInfo? {
        return profile.avatar
    }
    var displayName: String {
        return profile.nickname
    }
    var username: String {
        return profile.username
    }
    var character: Alien? {
        return profile.alien
    }
    let actionTitle: String = Localized.phrases.follow
    let selectedActionTitle: String? = Localized.phrases.following
    
    let profile: UserProfileDisplayable
    
    init(profile: UserProfileDisplayable) {
        self.profile = profile
    }
}
