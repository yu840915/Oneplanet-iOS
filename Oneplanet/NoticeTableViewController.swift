//
//  NoticeTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class NoticeTableViewController: UITableViewController {
    
    private var notices: [Notice] = [] {
        didSet {
            groupNotices()
        }
    }
    private var groups: [NoticeGroup] = [] {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.feature.notice
        notices = [
            Notice(type: .followNotice, isRead: true),
            Notice(type: .giftFromOfficialAccount, isRead: true),
            Notice(type: .likeFromOfficialAccount, isRead: true),
            Notice(type: .profileReported, isRead: true),
            Notice(type: .postReported, isRead: true),
        ]
    }
    
    private func groupNotices() {
        let unreads =  notices.filter{!$0.isRead}
        let reads = notices.filter{$0.isRead}
        var list: [NoticeGroup] = []
        if !unreads.isEmpty {
            list.append(NoticeGroup(notices: unreads, label: .unread))
        }
        if !reads.isEmpty {
            list.append(NoticeGroup(notices: reads, label: .read))
        }
        groups = list
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups[section].notices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let notice = getNotice(at: indexPath)
        let reuseID: String
        switch notice.type {
        case .followNotice, .giftFromOfficialAccount, .likeFromOfficialAccount:
            reuseID = NoticeTableViewController.ReuseID.normalNoticeCell
        case .postReported, .profileReported:
            reuseID = NoticeTableViewController.ReuseID.warningNoticeCell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        return cell
    }
    
    private func getNotice(at indexPath: IndexPath) -> Notice {
        return groups[indexPath.section].notices[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let notice = getNotice(at: indexPath)
        return notice.type != .postReported
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notice = getNotice(at: indexPath)
        switch notice.type {
        case .followNotice, .giftFromOfficialAccount, .likeFromOfficialAccount:
            showProfilePage(for: notice)
        case .profileReported:
            switchToMyProfile()
        case .postReported: break
        }
    }
    
    private func showProfilePage(for notice: Notice) {
        
    }
    
    private func switchToMyProfile() {
        router.handle(DeepLinks.meTab)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let container = segue.destination as? PopUpContainerViewController {
            container.contentViewControllerSetUpBlock = {[weak self] content in
                self?.prepareContent(for: content as! GemActionPopUpViewController)
            }
        }
    }
    
    private func prepareContent(for controller: GemActionPopUpViewController) {
    }

}

extension NoticeTableViewController {
    struct SegueID {
        static let showPopup = "showPopup"
    }
    
    struct ReuseID {
        static let normalNoticeCell = "normalNoticeCell"
        static let warningNoticeCell = "warningNoticeCell"
    }
}


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
//    var user: User {get}
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
