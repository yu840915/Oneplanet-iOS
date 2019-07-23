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
    private var isMe: Bool = false
    private var idHeader: IDHeaderView?

    private var profileController: ProfileCollectionViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareIDHeaderIfNeeded()
        updateViewsForProfile()
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
        idHeader?.idLabel.text = profile.displayID
        profileController.profile = profile
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
            vc.configuration = isMe ? .forMe: .forOther
            vc.showFollowListAction = {[weak self] url in
                self?.showFollowList(with: url)
            }
            profileController = vc
        }
        if let vc = segue.destination as? FriendListsViewController {
            vc.profile = profile
            vc.followerList = UserList.followerList(for: profile, userSession: userSession)
            vc.followingList = UserList.followerList(for: profile, userSession: userSession)
            if let url = sender as? URL, url == DeepLinks.followingList {
                vc.preselectedTab = .following
            }
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? ReportReasonPickerTableViewController {
            vc.flowController = (sender as! ReportFlowController)
            vc.didFinishReport = {
                
            }
        }
    }
    
}

private extension UserProfileViewController {
    func showFollowList(with url: URL) {
        performSegue(withIdentifier: SegueID.showFriendLists, sender: url)
    }
    
    func copyID() {
        UIPasteboard.general.string = profile.displayID
        Toast.show(with: String(format: Localized.messageFormats.didCopyId, profile.displayID))
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
    }
}
