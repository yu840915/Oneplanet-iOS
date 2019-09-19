//
//  UserProfileViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var profile: User!
    private var getFollowCountsOperation: GetUserFollowCountsOperation?
    private var isMe: Bool = false
    private var idHeader: IDHeaderView?
    private var profileController: ProfileCollectionViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        isMe = profile.id == userSession.profile?.id
        prepareIDHeaderIfNeeded()
        updateViewsForProfile()
        getFollowCounts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController, nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if view.frame.minY != topPadding {
            navigationController?.view.setNeedsLayout()
        }
    }

    private func prepareIDHeaderIfNeeded() {
        guard !userSession.isGuest else { return }
        let header = IDHeaderView.fromDefaultNib()
        header.copyAction = {[weak self] in
            self?.copyID()
        }
        navigationItem.titleView = header
        idHeader = header
    }
    
    private func updateViewsForProfile() {
        idHeader?.idLabel.text = profile.username
        profileController.profile = profile
        if isMe {
            profileController.followCounts = userSession.followCounts.counts
        }
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func showActionSheet(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Localized.phrases.copyID, style: .default, handler: { (_) in
            self.copyID()
        }))
        sheet.addAction(UIAlertAction(title: Localized.phrases.follow, style: .default, handler: { (_) in
            self.followUser()
        }))
        sheet.addAction(UIAlertAction(title: Localized.phrases.unfollow, style: .destructive, handler: { (_) in
            self.followUser()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.block, style: .destructive, handler: { (_) in
            self.showBlockAlert()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.unblock, style: .destructive, handler: { (_) in
            self.showUnblockAlert()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.report, style: .destructive, handler: { (_) in
            self.startReportFlow()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? ProfileCollectionViewController {            
            vc.profile = profile
            vc.postList = PostList.userPostList(with: userSession, for: profile)
            vc.configuration = isMe ? .forMe: .forOther
            vc.showFollowListAction = {[weak self] url in
                self?.showFollowList(with: url)
            }
            vc.showPostDetailAction = {[weak self] post in
                self?.performSegue(withIdentifier: SegueID.showPostDetail, sender: post)
            }
            profileController = vc
        }
        if let vc = segue.destination as? FriendListsViewController {
            vc.profile = profile
            vc.followerList = UserList.followerList(for: profile, userSession: userSession)
            vc.followingList = UserList.followingList(for: profile, userSession: userSession)
            if let url = sender as? URL, url == DeepLinks.followingList {
                vc.preselectedTab = .following
            }
        }
        if let vc = segue.destination as? PostDetailViewController {
            vc.post = (sender as! Post)
            vc.canShowAuthorProfile = false
        }
        if let nav = segue.destination as? UINavigationController{
            if let vc = nav.viewControllers.first as? UserSessionDepending {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? ReportReasonPickerTableViewController {
                NavigationBarStyle.darkGray.configure(nav.navigationBar)
                vc.flowController = (sender as! ReportFlowController)
                vc.didFinishReport = {
                    
                }
            }
        }
    }
}

extension UIViewController {
    var topPadding: CGFloat {
        var navH: CGFloat = 0
        if let inset = view.window?.safeAreaInsets {
            navH = inset.top
        }
        return navH + UIApplication.shared.statusBarFrame.height
    }
}

private extension UserProfileViewController {
    func getFollowCounts() {
        guard !isMe && getFollowCountsOperation == nil else { return }
        let op = GetUserFollowCountsOperation(user: profile, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetFollowCounts()
            }
        }
        op.start()
        getFollowCountsOperation = op
    }
    
    func didGetFollowCounts() {
        let op = getFollowCountsOperation!
        getFollowCountsOperation = nil
        profileController.followCounts = op.counts
    }
    
    func showFollowList(with url: URL) {
        performSegue(withIdentifier: SegueID.showFriendLists, sender: url)
    }
    
    func copyID() {
        UIPasteboard.general.string = profile.username
        Toast.show(with: String(format: Localized.messageFormats.didCopyId, profile.username))
    }
    
    func followUser() {
    }
    
    func unfollowUser() {
    }
    
    func showBlockAlert() {
        let alert = UIAlertController(title: String(format: Localized.messageFormats.blockUserPrompt, profile.nickname), message: Localized.messages.blockDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized.titles.block, style: .default, handler: { (_) in
            self.blockUser()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func blockUser() {
        
    }
    
    func showUnblockAlert() {
        let alert = UIAlertController(title: String(format: Localized.messageFormats.unblockUserPrompt, profile.nickname), message: Localized.messages.unblockDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized.titles.unblock, style: .default, handler: { (_) in
            self.unblockUser()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func unblockUser() {
        
    }
    
    func startReportFlow() {
        performSegue(withIdentifier: SegueID.showReportFlow, sender: UserReportFlowController())
    }
}

extension UserProfileViewController {
    struct SegueID {
        static let showFriendLists = "showFriendLists"
        static let showReportFlow = "showReportFlow"
        static let showPostDetail = "showPostDetail"
    }
}
