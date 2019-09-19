//
//  MyProfileViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class MyProfileViewController: UIViewController, UserSessionDepending {
    var userSession: UserSession!
    var profile: UserProfileDisplayable! {
        return userSession.profile
    }
    
    private var profileController: ProfileCollectionViewController!
    private var idHeader: IDHeaderView?
    private var profileUpdateHandle: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareIDHeaderIfNeeded()
        profileUpdateHandle = userSession.profileDidUpdate.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateViewsForProfile()
            }
        }
        updateViewsForProfile()
        userSession.followCounts.refreshIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        userSession.followCounts.refreshIfNeeded()
    }
    
    func setNeedsRefresh() {
        profileController?.setNeedsRefresh()
    }
    
    private func prepareIDHeaderIfNeeded() {
        guard !userSession.isGuest else { return }
        let header = IDHeaderView.fromDefaultNib()
        header.copyAction = {[weak self] in
            self?.copyID()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: header)
        idHeader = header
    }
    
    private func updateViewsForProfile() {
        idHeader?.idLabel.text = profile.username
        profileController.profile = profile
        profileController.followCounts = userSession.followCounts.counts
    }
    
    private func copyID() {
        UIPasteboard.general.string = profile.username
        Toast.show(with: String(format: Localized.messageFormats.didCopyMyId, profile.username))
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProfileCollectionViewController {
            vc.userSession = userSession
            vc.postList = PostList.myPostList(with: userSession)
            vc.profile = profile
            vc.followCounts = userSession.followCounts.counts
            vc.configuration = userSession.isGuest ? .forGuest: .forMe
            vc.showFollowListAction = {[weak self] url in
                self?.showFollowList(with: url)
            }
            vc.showPostDetailAction = {[weak self] post in
                self?.performSegue(withIdentifier: SegueID.showPostDetail, sender: post)
            }
            vc.shouldShowWarning = userSession.isBanned
            profileController = vc
        }
        if let nav = segue.destination as? UINavigationController{
            if let vc = nav.viewControllers.first as? UserSessionDepending {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? FriendListsViewController {
                NavigationBarStyle.darkGray.configure(nav.navigationBar)
                vc.userSession = userSession
                vc.profile = profile
                vc.followerList = UserList.followerList(with: userSession)
                vc.followingList = UserList.followerList(with: userSession)
                if let url = sender as? URL, url == DeepLinks.followingList {
                    vc.preselectedTab = .following
                }
            } else if let vc = nav.viewControllers.first as? PostDetailViewController {
                vc.post = (sender as! Post)
                vc.canShowAuthorProfile = false
            }
        }
    }
}

extension MyProfileViewController {
    struct SegueID {
        static let showFriendLists = "showFriendLists"
        static let showPostDetail = "showPostDetail"
    }
}

extension MyProfileViewController {
   func showFollowList(with url: URL) {
        performSegue(withIdentifier: SegueID.showFriendLists, sender: url)
    }
}

extension MyProfileViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        profileController.collectionView.setContentOffset(.zero, animated: true)
    }
}
