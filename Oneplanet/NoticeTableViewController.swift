//
//  NoticeTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class NoticeTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var noticeList: NoticeList!
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
    private var listUpdateHandles: [Any]?
    private weak var actionPopUp: GemActionPopUpViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareNoticeList()
        tableView.register(SectionHeaderView.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.header)
        title = Localized.feature.notice
        notices = [
            Notice(type: .followNotice, isRead: true),
            Notice(type: .giftFromOfficialAccount, isRead: true),
            Notice(type: .likeFromOfficialAccount, isRead: true),
            Notice(type: .profileReported, isRead: true),
            Notice(type: .postReported, isRead: true),
        ]
    }

    @IBAction func reloadList(_ sender: UIRefreshControl) {
        noticeList.reload()
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
                self?.performFollowAction(for: notice)
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
    

    private func performFollowAction(for notice: Notice) {
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let result = tableView.dequeueReusableHeaderFooterView(withIdentifier: ReuseID.header) as! SectionHeaderView
        switch groups[section].label {
        case .read:
            result.titleLabel.text = Localized.phrases.newNotices
        case .unread:
            result.titleLabel.text = Localized.phrases.readNotices
        }
        result.titleLabel.textColor = ColorPalette.defaultText
        result.separator.isHidden = true
        return result
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastSection = indexPath.section == (groups.count - 1)
        let isLastRow = indexPath.row == (groups[indexPath.section].notices.count - 1)
        if isLastSection && isLastRow && noticeList.hasMore {
            noticeList.loadMoreIfAllowed()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let container = segue.destination as? PopUpContainerViewController {
            container.contentViewControllerSetUpBlock = {[weak self] content in
                let vc = content as! GemActionPopUpViewController
                vc.configuration = (sender as! GemActionPopUpConfiguration)
                self?.actionPopUp = vc
            }
        }
    }
}

private extension NoticeTableViewController {
    func prepareNoticeList() {
        noticeList = NoticeList(session: userSession)
        var handles = [Any]()
        handles.append(noticeList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(noticeList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        listUpdateHandles = handles
        noticeList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        notices = noticeList.items
        updateBackgroun()
    }
    
    func handleFetchFailure(with error: Error?) {
        refreshControl?.endRefreshing()
        updateBackgroun(with: error)
    }
    
    func updateBackgroun(with error: Error? = nil) {
        if !notices.isEmpty {
            tableView.backgroundView = nil
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            view.titleLabel.text = Localized.emptyMessages.notices
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            tableView.backgroundView = view
        }
    }
    
    func groupNotices() {
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
    
    func redeemGemsIfAllowed(for notice: Notice) {
        if actionPopUp != nil {
            dismiss(animated: true, completion: nil)
        }
    }
}

private extension NoticeTableViewController {
    func showProfilePage(for notice: Notice) {
    }
    
    func switchToMyProfile() {
        router.handle(DeepLinks.meTab)
    }
    
    func showGetGemPopUp(for notice: Notice) {
        var config: GemActionPopUpConfiguration?
        switch notice.type {
        case .giftFromOfficialAccount:
            config = GiftFromOfficialNoticePopUpConfiguration(notice: notice)
        case .likeFromOfficialAccount:
            config = LikeFromOfficialNoticePopUpConfiguration(notice: notice)
        default: return
        }
        config?.mainAction = {[weak self] in
            self?.redeemGemsIfAllowed(for: notice)
        }
        performSegue(withIdentifier: SegueID.showPopup, sender: config)
    }
    
}

extension NoticeTableViewController {
    struct SegueID {
        static let showPopup = "showPopup"
    }
    
    struct ReuseID {
        static let normalNoticeCell = "normalNoticeCell"
        static let warningNoticeCell = "warningNoticeCell"
        static let header = "header"
    }
}
