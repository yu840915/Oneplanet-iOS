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

protocol FollowCountsProvider {
    var followers: Int {get}
    var followings: Int {get}
}

struct FakeCount: FollowCountsProvider {
    var followers: Int = 1000
    var followings: Int = 1530
}

class ProfileDetailViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    class var baseHeight: CGFloat {
        return 90 + UIScreen.main.bounds.width
    }
    class var warningHeight: CGFloat {
        return 184 + baseHeight
    }

    var userSession: UserSession!
    var showFollowListAction: ((URL)->())?
    var followCountsProvider: FollowCountsProvider? {
        didSet {
            if isViewLoaded {
                updateViewsForFollowCounts()
            }
        }
    }
    var shouldShowWarning = false {
        didSet {
            if isViewLoaded {
                warningView.isHidden = !shouldShowWarning
            }
        }
    }
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
    @IBOutlet weak var countsTextView: UITextView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var raceImageView: UIImageView!
    @IBOutlet weak var warningView: BanWarningView!
    
    var profile: UserProfileDisplayable? {
        didSet {
            if isViewLoaded {
                updateViewsForProfile()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        updateViewsForProfile()
        updateViewsForFollowCounts()
        followCountsProvider = FakeCount()
        warningView.isHidden = !shouldShowWarning
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
        countsTextView.isHidden = !configuration.detailLabel
        avatarView.avatar = profile.avatar
    }
    
    private func updateViewsForFollowCounts() {
        guard let provider = followCountsProvider else { return }
        let followerCount = SharedNumberFormatters.roughNumber.string(for: provider.followers)
        let follower = String(format: Localized.phraseFormats.followers, followerCount)
        let followingsCount = SharedNumberFormatters.roughNumber.string(for: provider.followings)
        let followings = String(format: Localized.phraseFormats.followings, SharedNumberFormatters.roughNumber.string(for: provider.followings))
        let text = [follower, followings].joined(separator: Localized.symbols.enumSpliter)
        let followerCountRange = (text as NSString).range(of: followerCount)
        let followerRange = (text as NSString).range(of: follower)
        let followingsCountRange = (text as NSString).range(of: followingsCount)
        let followingRange = (text as NSString).range(of: followings)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText])
        attrStr.addAttributes([.link : DeepLinks.followerList], range: followerRange)
        attrStr.addAttributes([.link : DeepLinks.followingList], range: followingRange)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], range: followerCountRange)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], range: followingsCountRange)
        countsTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.defaultText,
            .font: UIFont.systemFont(ofSize: 14)]
        countsTextView.attributedText = attrStr
    }
    
    @IBAction func performAction(_ sender: UIButton) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? CharacterPickerViewController {
            vc.draft = ProfileDraft(profile: userSession.profile!)
        }
    }
}

extension ProfileDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.showFollowListAction?(URL)
        }
        return false
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

class BanWarningView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.warningTitles.accountBanned
        detailLabel.text = Localized.warnings.accountBanned
        actionButton.setTitle(Localized.phrases.recoverAccount, for: .normal)
    }
}
