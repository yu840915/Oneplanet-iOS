//
//  ProfileDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol UserProfileDisplayable {
    var displayID: String {get}
    var nickname: String {get}
    var avatar: WebImageInfo? {get}
    var character: Character? {get}
}

class ProfileDetailViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    var userSession: UserSession!
    var configuration: DisplayConfiguration = .forGuest {
        didSet {
            if isViewLoaded {
                updateViewsForProfile()
            }
        }
    }
    
    class func fromDefaultStoryboard() -> ProfileDetailViewController {
        return UIStoryboard(name: "Me", bundle: nil).instantiateViewController(withIdentifier: "ProfileDetailViewController") as! ProfileDetailViewController
    }
    
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var raceImageView: UIImageView!
    var profile: UserProfileDisplayable? {
        didSet {
            if isViewLoaded {
                updateViewsForProfile()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: UIView.noIntrinsicMetric, height: 475)
        localizeTitles()
        updateViewsForProfile()
    }
    
    private func localizeTitles() {
        actionButton.setTitle(Localized.phrases.follow, for: .normal)
        actionButton.setTitle(Localized.phrases.following, for: .selected)
        actionButton.setTitle(Localized.phrases.following, for: [.selected, .highlighted])
    }
    
    private func updateViewsForProfile() {
        guard let profile = self.profile else { return }
        avatarView.backgrondImage = profile.character?.race.frameImage
        nicknameLabel.text = profile.nickname
        if let image = profile.character?.avatar {
            raceImageView.image = image
        }
        actionButton.isHidden = !configuration.actionButton
        detailLabel.isHidden = !configuration.detailLabel
        avatarView.avatar = profile.avatar
    }
    
    @IBAction func performAction(_ sender: UIButton) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? CharacterPickerViewController {
            vc.userSession = userSession
            vc.draft = ProfileDraft(profile: userSession.profile!)
        }
    }
}

extension ProfileDetailViewController {
    struct SegueID {
    }
    
    struct DisplayConfiguration {
        let actionButton: Bool
        let detailLabel: Bool
        static let forMe = DisplayConfiguration(actionButton: false, detailLabel: true)
        static let forOther = DisplayConfiguration(actionButton: true, detailLabel: true)
        static let forGuest = DisplayConfiguration(actionButton: false, detailLabel: false)
    }
}
