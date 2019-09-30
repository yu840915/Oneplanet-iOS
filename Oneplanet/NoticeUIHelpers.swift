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
        super.updateViews(with: dataSource)
        avatarView.update(with: dataSource.user)
        actionButton.setTitle(dataSource.actionTitle, for: .normal)
        actionButton.setTitle(dataSource.selectedActionTitle, for: .selected)
        actionButton.setTitle(dataSource.selectedActionTitle, for: [.selected, .highlighted])
        actionButton.setTitle(dataSource.selectedActionTitle, for: .disabled)
    }
}

protocol WarningNoticeItemDisplayable: NoticeItemDisplayable {
    var contentImage: WebImageInfo? { get }
}


class WarningNoticeItemCell: NoticeItemCell {
    @IBOutlet weak var contentImageView: UIImageView!
    private var fetchOperation: DownloadImageOperaion?
    
    func updateViews(with dataSource: WarningNoticeItemDisplayable) {
        super.updateViews(with: dataSource)
        if let info = dataSource.contentImage {
            if fetchOperation?.info.url == info.url {
                return
            }
            let op = DownloadImageOperaion(info: info)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.updateCover()
                }
            }
            fetchOperation = op
            op.start()
        } else {
            fetchOperation?.cancel()
            fetchOperation = nil
        }
    }
    
    private func updateCover() {
        guard let op = fetchOperation, let image = op.image else {return}
        contentImageView.image = image
    }
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
        return NSAttributedString(string: String(format: Localized.messageFormats.profileReported, account, Localized.titles.tos), attributes: [.font:  UIFont.systemFont(ofSize: 12)])
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

class DailyRewardNoticePopUpConfiguration: GemActionPopUpConfiguration {
    let event: BonusEvent
    
    init(event: BonusEvent) {
        self.event = event
    }
    
    override var icon: UIImage {
        switch event.info!.currency {
        case .greenGem:
            return #imageLiteral(resourceName: "im_05_emerkey")
        case .blueGem:
            return #imageLiteral(resourceName: "im_06_safrid")
        case .purpleGem:
            return #imageLiteral(resourceName: "im_07_rubid")
        case .score:
            return UIImage()
        }
    }
    
    override var attributedSubtitle: NSAttributedString {
        let gem = event.info!.currency.displayName
        let text = String(format: Localized.messageFormats.dailyLoginReward, gem)
        let attrStr = NSMutableAttributedString(string: text, attributes: subtitleAttributes)
        let gemRange = (text as NSString).range(of: gem)
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

class GiftFromOfficialNoticePopUpConfiguration: GemActionPopUpConfiguration {
    let event: BonusEvent
    let user: User
    
    init(event: BonusEvent, user: User) {
        self.event = event
        self.user = user
    }

    override var icon: UIImage {
        switch event.info!.currency {
        case .greenGem:
            return #imageLiteral(resourceName: "im_05_emerkey")
        case .blueGem:
            return #imageLiteral(resourceName: "im_06_safrid")
        case .purpleGem:
            return #imageLiteral(resourceName: "im_07_rubid")
        case .score:
            return UIImage()
        }
    }
    
    override var attributedSubtitle: NSAttributedString {
        let gem = event.info!.currency.displayName
        let name = user.nickname
        let num = SharedNumberFormatters.integer.string(for: event.info!.amount) ?? "-"
        let text = String(format: Localized.messageFormats.gaveYouNumberGems, name, gem, num)
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
    let event: BonusEvent
    let user: User

    init(event: BonusEvent, user: User) {
        self.event = event
        self.user = user
    }

    override var icon: UIImage {
        switch event.info!.currency {
        case .greenGem:
            return #imageLiteral(resourceName: "im_05_emerkey")
        case .blueGem:
            return #imageLiteral(resourceName: "im_06_safrid")
        case .purpleGem:
            return #imageLiteral(resourceName: "im_07_rubid")
        case .score:
            return UIImage()
        }
    }
    
    override var attributedSubtitle: NSAttributedString {
        let gem = event.info!.currency.displayName
        let official = user.nickname
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
