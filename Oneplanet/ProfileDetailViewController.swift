//
//  ProfileDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol UserProfileDisplayable {
    var id: String {get}
    var nickname: String {get}
    var avatar: WebImageInfo? {get}
    var race: Race? {get}
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
    
    @IBOutlet weak var chooseRaceButton: UIButton!
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
        chooseRaceButton.setTitle(Localized.phrases.chooseRole, for: .normal)
    }
    
    private func updateViewsForProfile() {
        guard let profile = self.profile else { return }
        avatarView.borderColor = profile.race?.color
        nicknameLabel.text = profile.nickname
        if let image = profile.race?.avatar {
            raceImageView.image = image
        }
        chooseRaceButton.isHidden = !configuration.raceButton
        actionButton.isHidden = !configuration.actionButton
        detailLabel.isHidden = !configuration.detailLabel
        avatarView.avatar = profile.avatar
    }
    
    @IBAction func startChooseRece(_ sender: UIButton) {
    }
    
    @IBAction func performAction(_ sender: UIButton) {
    }
}

extension ProfileDetailViewController {
    struct DisplayConfiguration {
        let raceButton: Bool
        let actionButton: Bool
        let detailLabel: Bool
        static let forMe = DisplayConfiguration(raceButton: true, actionButton: false, detailLabel: true)
        static let forOther = DisplayConfiguration(raceButton: false, actionButton: true, detailLabel: true)
        static let forGuest = DisplayConfiguration(raceButton: false, actionButton: false, detailLabel: false)
    }
}
