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
        idHeader?.idLabel.text = profile.id
        profileController.profile = profile
    }
    private func copyID() {
        UIPasteboard.general.string = profile.id
        Toast.show(with: String(format: Localized.messageFormats.didCopyMyId, profile.id))
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProfileCollectionViewController {
            vc.userSession = userSession
            vc.profile = profile
            vc.configuration = userSession.isGuest ? .forGuest: .forMe
            profileController = vc
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? SettingsTableViewController {
            vc.userSession = userSession
        }
    }

}

extension MyProfileViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        profileController.collectionView.setContentOffset(.zero, animated: true)
    }
}
