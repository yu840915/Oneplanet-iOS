//
//  NoticeUIHelpers.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class NoticeGroup {
    let label: Label
    let notices: [Notice]
    init(notices: [Notice], label: Label) {
        self.notices = notices
        self.label = label
    }
    
    enum Label {
        case unread
        case read
    }
}

protocol NoticeItemDisplayable {
    var attributedMessage: NSAttributedString {get}
    var pastTime: String {get}
}

class NoticeViewModel: NoticeItemDisplayable {
    let notice: Notice
    init(notice: Notice) {
        self.notice = notice
    }
    
    var attributedMessage: NSAttributedString {
        return NSAttributedString(string: "")
    }
    var pastTime: String {
        return SharedSpeciaFormatters.dateFromNowForNotices.string(from: notice.date)
    }
}

class NoticeItemCell: UITableViewCell {
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    func updateViews(with dataSource: NoticeItemDisplayable) {
        messageLabel.attributedText = dataSource.attributedMessage
        timeLabel.text = dataSource.pastTime
    }
}

protocol NormalNoticeItemDisplayable: NoticeItemDisplayable {
    var actionTitle: String {get}
    var selectedActionTitle: String? {get}
    var user: User? {get}
}

class LikeFromOfficialNoticeViewModel: NoticeViewModel, NormalNoticeItemDisplayable {
    private let userFetcher: UserFetcher?
    private let event: BonusEventInfo
    var user: User? {
        return userFetcher?.user
    }
    
    init(notice: Notice, eventInfo: BonusEventInfo, userSession: UserSession) {
        userFetcher = userSession.userFetcherRepo.fetcher(for: eventInfo.senderID)
        userFetcher?.initializeIfNeeded()
        event = eventInfo
        super.init(notice: notice)
    }
    
    override var attributedMessage: NSAttributedString {
        let nickname = user?.nickname ?? "-"
        let currency = event.currency.displayName
        let text = String(format: Localized.messageFormats.likedYourPost, nickname, currency)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        let range = (text as NSString).range(of: nickname)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: range)
        return attrStr
    }
    
    
    let actionTitle: String = Localized.phrases.getGem
    let selectedActionTitle: String? = Localized.phrases.hasGotGem
}

class EmptyBonusNoticeViewModel: NoticeViewModel, NormalNoticeItemDisplayable {
    let actionTitle: String = Localized.phrases.getGem
    let selectedActionTitle: String? = Localized.phrases.hasGotGem
    let user: User? = nil
}

class LoginRewardNoticeViewModel: NoticeViewModel, NormalNoticeItemDisplayable {
    let user: User? = nil
    let event: BonusEventInfo

    init(notice: Notice, eventInfo: BonusEventInfo) {
        event = eventInfo
        super.init(notice: notice)
    }
    
    override var attributedMessage: NSAttributedString {
        let currency = event.currency.displayName
        
        let text = String(format: Localized.messageFormats.dailyLoginReward, currency)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        let gemRange = (text as NSString).range(of: currency)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: gemRange)
        return attrStr
    }
    
    let actionTitle: String = Localized.phrases.getGem
    let selectedActionTitle: String? = Localized.phrases.hasGotGem
}

class GiftFromOfficialNoticeViewModel: NoticeViewModel, NormalNoticeItemDisplayable {
    private let userFetcher: UserFetcher?
    private let event: BonusEventInfo
    var user: User? {
        return userFetcher?.user
    }
    
    init(notice: Notice, eventInfo: BonusEventInfo, userSession: UserSession) {
        userFetcher = userSession.userFetcherRepo.fetcher(for: eventInfo.senderID)
        userFetcher?.initializeIfNeeded()
        event = eventInfo
        super.init(notice: notice)
    }

    override var attributedMessage: NSAttributedString {
        let nickname = user?.nickname ?? "-"
        let currency = event.currency.displayName
        var num = "-"
        num = SharedNumberFormatters.integer.string(for: event.amount) ?? "-"

        let text = String(format: Localized.messageFormats.gaveYouNumberGems, nickname, currency, num)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        let numRange = (text as NSString).range(of: num)
        let gemRange = (text as NSString).range(of: currency)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: numRange)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: gemRange)
        return attrStr
    }

    let actionTitle: String = Localized.phrases.getGem
    let selectedActionTitle: String? = Localized.phrases.hasGotGem
}

class FollowNoticeViewModel: NoticeViewModel, NormalNoticeItemDisplayable {
    let userFetcher: UserFetcher
    var user: User? {
        return userFetcher.user
    }
    
    init(notice: FollowNotice, userSession: UserSession) {
        userFetcher = userSession.userFetcherRepo.fetcher(for: notice.followerID)
        userFetcher.initializeIfNeeded()
        super.init(notice: notice)
    }

    override var attributedMessage: NSAttributedString {
        let nickname = user?.nickname ?? "-"
        let text = String(format: Localized.messageFormats.startFollowingYou, nickname)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        let range = (text as NSString).range(of: nickname)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: range)
        return attrStr
    }
    
    let actionTitle: String = Localized.phrases.follow
    let selectedActionTitle: String? = Localized.phrases.following

}

class NormalNoticeItemCell: NoticeItemCell {
    var action: (()->())? {
        didSet {
            actionButton.isUserInteractionEnabled = (action != nil)
        }
    }
    @IBOutlet weak var actionButton: UIButton!
    
    @IBAction func invokeAction(_ sender: UIButton) {
        action?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        actionButton.setImage(actionButton.backgroundImage(for: .highlighted), for: [.selected, .highlighted])
    }
    
    func updateViews(with dataSource: NormalNoticeItemDisplayable) {
        avatarView.update(with: dataSource.user)
        super.updateViews(with: dataSource)
        actionButton.setTitle(dataSource.actionTitle, for: .normal)
        actionButton.setTitle(dataSource.selectedActionTitle, for: .selected)
        actionButton.setTitle(dataSource.selectedActionTitle, for: [.selected, .highlighted])
    }
}

protocol WarningNoticeItemDisplayable: NoticeItemDisplayable {
    var contentImage: WebImageInfo? { get }
}


class WarningNoticeItemCell: NoticeItemCell {
    @IBOutlet weak var contentImageView: UIImageView!
}

class ProfileReportedViewModel: NoticeViewModel, WarningNoticeItemDisplayable {
    let account: String
    let reasonKey: String
    let contentImage: WebImageInfo? = nil

    init(notice: ProfileReportedNotice, userSession: UserSession) {
        account = userSession.profile?.username ?? userSession.loginType.displayName
        reasonKey = notice.reason
        super.init(notice: notice)
    }
    
    override var attributedMessage: NSAttributedString {
        let reason = Localized.lookUp(reasonKey)
        return NSAttributedString(string: String(format: Localized.messageFormats.profileReported, account, reason), attributes: [.font:  UIFont.systemFont(ofSize: 12)])
    }
}

class PostReportedViewModel: NoticeViewModel, WarningNoticeItemDisplayable {
    let reasonKey: String
    let contentImage: WebImageInfo?
    
    init(notice: PostReportedNotice, postCover: WebImageInfo?) {
        contentImage = postCover
        reasonKey = notice.reason
        super.init(notice: notice)
    }
    
    override var attributedMessage: NSAttributedString {
        let reason = Localized.lookUp(reasonKey)
        return NSAttributedString(string: String(format: Localized.messageFormats.postReported, reason), attributes: [.font:  UIFont.systemFont(ofSize: 12)])
    }
}

class LikeFromOfficalNoticePopUpConfiguration: GemActionPopUpConfiguration {
    
}

class GiftFromOfficialNoticePopUpConfiguration: GemActionPopUpConfiguration {
    let notice: Notice
    init(notice: Notice) {
        self.notice = notice
    }
    
    override var icon: UIImage {
        return #imageLiteral(resourceName: "im_06_safrid")
    }
    
    override var attributedSubtitle: NSAttributedString {
        let name = "Supreme.AI"
        let gem = Localized.titles.blueGem
        let num = "3"
        let text = String(format: Localized.messageFormats.gaveYouNumberGems, name, num, gem)
        let attrStr = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        let numRange = (text as NSString).range(of: num)
        let gemRange = (text as NSString).range(of: gem)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: numRange)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: gemRange)
        return attrStr
    }
    
    override var actionTitle: String {
        return Localized.phrases.getGem
    }
    override var shouldShowTitle: Bool {
        return false
    }
    override var shouldShowCancel: Bool {
        return false
    }
}

class LikeFromOfficialNoticePopUpConfiguration: GemActionPopUpConfiguration {
    let notice: Notice
    init(notice: Notice) {
        self.notice = notice
    }

    override var icon: UIImage {
        return #imageLiteral(resourceName: "im_06_safrid")
    }
    
    override var attributedSubtitle: NSAttributedString {
        let gem = Currency.greenGem.displayName
        let official = "Supreme.AI"
        let text = String(format: Localized.messageFormats.likedYourPostAndGaveGem, official, gem)
        let attrStr = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        let nameRange = (text as NSString).range(of: official)
        let gemRange = (text as NSString).range(of: gem)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: nameRange)
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: gemRange)
        return attrStr
    }
    override var actionTitle: String {
        return Localized.phrases.getGem
    }
    override var shouldShowTitle: Bool {
        return false
    }
    override var shouldShowCancel: Bool {
        return false
    }
}
