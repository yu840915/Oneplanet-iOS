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
                prepareSections()
            }
        }
    }
    var sections: [Section] = []
    private var listUpdateHandles: [Any]?
    private weak var actionPopUp: GemActionPopUpViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareNoticeList()
        tableView.register(SectionHeaderView.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.header)
        title = Localized.feature.notice
    }

    @IBAction func reloadList(_ sender: UIRefreshControl) {
        noticeList.reload()
    }
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .content: return groups[section].notices.count
        case .loading: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections[indexPath.section] == .loading {
            return tableView.dequeueReusableCell(withIdentifier: ReuseID.loading, for: indexPath)
        }
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section] == .loading {
            return 0.1
        }
        return 28
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sections[section] == .loading {
            return UIView()
        }
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
        if sections[indexPath.section] == .loading {
            return false
        }

        let notice = getNotice(at: indexPath)
        return notice.type != .postReported
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .loading {
            return
        }
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
        if sections[indexPath.section] == .loading {
            (cell as! LoadingCell).activityIndicator.startAnimating()
            return
        }

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
        updateBackground()
    }
    
    func handleFetchFailure(with error: Error?) {
        refreshControl?.endRefreshing()
        updateBackground(with: error)
    }
    
    func updateBackground(with error: Error? = nil) {
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
    
    func prepareSections() {
        let hasContent = !groups.isEmpty
        let hasMore = noticeList.hasMore
        var val: [Section] = [Section](repeating: .content, count: groups.count)
        if hasContent && hasMore {
            val.append(.loading)
        }
        sections = val
        tableView.reloadData()
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
    enum Section: String {
        case content
        case loading
    }

    struct ReuseID {
        static let normalNoticeCell = "normalNoticeCell"
        static let warningNoticeCell = "warningNoticeCell"
        static let header = "header"
        static let loading = "loadingCell"
    }
}
