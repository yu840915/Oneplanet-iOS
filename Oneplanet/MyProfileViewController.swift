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
    
    @IBOutlet weak var addPostButton: UIButton!
    private var profileController: ProfileCollectionViewController!
    private var idHeader: IDHeaderView!
    var profile: UserProfileDisplayable!  = FakeProfile()

    override func viewDidLoad() {
        super.viewDidLoad()
        let header = IDHeaderView.fromDefaultNib()
        header.copyAction = {[weak self] in
            self?.copyID()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: header)
        idHeader = header
        addPostButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addPostButton.layer.shadowRadius = 4
        addPostButton.layer.shadowColor = UIColor.black.cgColor
        addPostButton.layer.shadowOpacity = 0.5
        updateViewsForProfile()
    }
    
    private func updateViewsForProfile() {
        idHeader.idLabel.text = profile.id
    }
    private func copyID() {
        UIPasteboard.general.string = profile.id
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ProfileCollectionViewController {
            vc.userSession = userSession
            vc.profile = profile
            profileController = vc
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? SettingsTableViewController {
            vc.userSession = userSession
        }
    }

}

fileprivate class FakeProfile: UserProfileDisplayable {
    var id: String = "asdf5465413"
    
    var nickname: String = "Mike"
    
    var avatarURL: WebImageInfo = WebImageInfo(url: ServiceURLs.base.appendingPathComponent("/me/avatar"), accessToken: nil)
    
    var race: Race? = Race(color: .blue, avatar: #imageLiteral(resourceName: "im_userphotodefault_nor"))
}
