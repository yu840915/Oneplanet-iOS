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
        
        switch notice.type {
        case .followNotice, .giftFromOfficialAccount, .likeFromOfficialAccount:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.normalNoticeCell, for: indexPath) as! NormalNoticeItemCell
            setUpNormalNoticeCell(cell, forNoticeAt: indexPath)
            return cell
        case .postReported, .profileReported:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.warningNoticeCell, for: indexPath) as! WarningNoticeItemCell
            setUpWarningNoticeCell(cell, forNoticeAt: indexPath)
            return cell
        }
    }
    
    private func setUpNormalNoticeCell(_ cell: NormalNoticeItemCell, forNoticeAt indexPath: IndexPath) {
        let notice = getNotice(at: indexPath)
        switch notice.type {
        case .followNotice:
            cell.updateViews(with: FollowNoticeViewModel(notice: notice))
            cell.action = {[weak self] in
                self?.showFollowAction(for: notice)
            }
        case .giftFromOfficialAccount:
            cell.updateViews(with: GiftFromOfficialNoticeViewModel(notice: notice))
            cell.action = {[weak self] in
                self?.showGetGemPopUp(for: notice)
            }
        case .likeFromOfficialAccount:
            cell.updateViews(with: LikeFromOfficialNoticeViewModel(notice: notice))
            cell.action = {[weak self] in
                self?.showGetGemPopUp(for: notice)
            }
        default: break
        }
    }
    
    private func setUpWarningNoticeCell(_ cell: WarningNoticeItemCell, forNoticeAt indexPath: IndexPath) {
        let notice = getNotice(at: indexPath)
        switch notice.type {
        case .profileReported:
            cell.updateViews(with: ProfileReportedViewModel(notice: notice))
        case .postReported:
            cell.updateViews(with: PostReportedViewModel(notice: notice))
        default: break
        }
    }
    
    private func getNotice(at indexPath: IndexPath) -> Notice {
        return groups[indexPath.section].notices[indexPath.row]
    }
    
    private func showGetGemPopUp(for notice: Notice) {
        var config: GemActionPopUpConfiguration?
        switch notice.type {
        case .giftFromOfficialAccount:
            config = GiftFromOfficialNoticePopUpConfiguration(notice: notice)
        case .likeFromOfficialAccount:
            config = LikeFromOfficialNoticePopUpConfiguration(notice: notice)
        default: return
        }
        performSegue(withIdentifier: SegueID.showPopup, sender: config)
    }
    
    private func showFollowAction(for notice: Notice) {
        
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let notice = getNotice(at: indexPath)
        return notice.type != .postReported
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
            container.contentViewControllerSetUpBlock = {content in
                let vc = content as! GemActionPopUpViewController
                vc.configuration = (sender as! GemActionPopUpConfiguration)
            }
        }
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
