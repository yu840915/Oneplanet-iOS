//
//  NoticeTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Alamofire

class NoticeTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var bonusEventRepo: BonusEventRepository!
    var noticeList: NoticeList!
    var unreadCount: NoticeUnreadCount!
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
    private var updateClock: UpdateClock!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bonusEventRepo = BonusEventRepository(userSession: userSession)
        prepareNoticeList()
        tableView.register(SectionHeaderView.defaultNib(), forHeaderFooterViewReuseIdentifier: ReuseID.header)
        title = Localized.feature.notice
        updateClock = UpdateClock(preferredFrameRate: 4, onTick: {[weak self] in
            self?.updateVisibleCells()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let count = unreadCount.count, count > 0 {
            noticeList.reload()
        }
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
        case .followNotice, .bonus:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.normalNoticeCell, for: indexPath) as! NormalNoticeItemCell
            setUpNormalNoticeCell(cell, forNoticeAt: indexPath)
            return cell
        case .reported, .banned:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.warningNoticeCell, for: indexPath) as! WarningNoticeItemCell
            setUpWarningNoticeCell(cell, forNoticeAt: indexPath)
            return cell
        case .unknwon: return UITableViewCell()
        }
    }
    
    private func setUpNormalNoticeCell(_ cell: NormalNoticeItemCell, forNoticeAt indexPath: IndexPath) {
        let notice = getNotice(at: indexPath)
        if let follow = notice as? FollowNotice {
            cell.updateViews(with: FollowNoticeViewModel(notice: follow, userSession: userSession))
            cell.action = {[weak self] in
                self?.performFollowAction(for: follow)
            }
            cell.actionButton.isEnabled = true
            if let relationStates = userSession.socialRelationshipRepo.relationshipWithUser(of: follow.followerID)?.states {
                cell.actionButton.isHidden = false
                cell.actionButton.isSelected = relationStates.isFollowing
            } else {
                cell.actionButton.isHidden = true
            }
            
        } else if let bonus = notice as? BonusNotice {
            let event = bonusEventRepo.event(for: bonus.eventID)
            if event.info != nil {
                setUpBonusNoticeCell(cell, for: bonus)
                cell.action = {[weak self] in
                    self?.showGetGemPopUp(for: bonus)
                }
            } else {
                cell.updateViews(with: EmptyBonusNoticeViewModel(notice: notice))
                cell.actionButton.isHidden = true
                cell.action = nil
            }
        }
        cell.avatarView.action = {[weak self] in
            self?.showProfilePage(for: notice)
        }
    }
    
    private func setUpBonusNoticeCell(_ cell: NormalNoticeItemCell, for notice: BonusNotice) {
        let event = bonusEventRepo.event(for: notice.eventID)
        guard let info = event.info else {
            return
        }
        switch info.type {
        case .gift:
            cell.updateViews(with: GiftFromOfficialNoticeViewModel(notice: notice, eventInfo: info, userSession: userSession))
        case .likePost:
            cell.updateViews(with: LikeFromOfficialNoticeViewModel(notice: notice, eventInfo: info, userSession: userSession))
        case .loginReward:
            cell.updateViews(with: LoginRewardNoticeViewModel(notice: notice, eventInfo: info))
        }
        cell.actionButton.isEnabled = !event.isRedeemed
        cell.actionButton.isHidden = false
    }
    
    private func setUpWarningNoticeCell(_ cell: WarningNoticeItemCell, forNoticeAt indexPath: IndexPath) {
        let notice = getNotice(at: indexPath)
        if let profile = notice as? ProfileReportedNotice {
            cell.updateViews(with: ProfileReportedViewModel(notice: profile, userSession: userSession))
        } else if let postNotice = notice as? PostReportedNotice {
            let thumbnail = WebImageInfo(url: ServiceURLs.base.appendingPathComponent("posts/\(postNotice.postID)/thumbnail"), accessToken: userSession.bearerToken)
            cell.updateViews(with: PostReportedViewModel(notice: postNotice, postCover: thumbnail))
        }
    }
    
    private func getNotice(at indexPath: IndexPath) -> Notice {
        return groups[indexPath.section].notices[indexPath.row]
    }
    

    private func performFollowAction(for notice: FollowNotice) {
        guard let relationship = userSession.socialRelationshipRepo.relationshipWithUser(of: notice.followerID), let states = relationship.states else { return }
        if states.isFollowing {
            relationship.unfollow()
        } else {
            relationship.follow()
        }
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
        case .unread:
            result.titleLabel.text = Localized.phrases.newNotices
        case .read:
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
        return notice.type != .reported
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section] == .loading {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let notice = getNotice(at: indexPath)
        switch notice.type {
        case .followNotice, .bonus:
            showProfilePage(for: notice)
        case .banned:
            switchToMyProfile()
        case .reported, .unknwon: break
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
        } else if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? UserProfileViewController {
            vc.userSession = userSession
            vc.profile = (sender as! User)
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
        if let count = unreadCount.count, count > 0 {
            unreadCount.refresh()
        }
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

    func redeemGemsIfAllowed(for bonus: BonusEvent) {
        if actionPopUp != nil {
            dismiss(animated: true, completion: nil)
        }
        bonus.redeemIfAllowed {[weak self] (_, error) in
            OperationQueue.main.addOperation {
                self?.showAlertIfNeeded(for: error)
            }
        }
    }
    
    private func showAlertIfNeeded(for error: Error?) {
        guard let error = error else { return }
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

private extension NoticeTableViewController {
    func updateVisibleCells() {
        let indexPaths = tableView.indexPathsForVisibleRows?.filter{sections[$0.section] == .content} ?? []
        indexPaths.forEach{updateVisibleCell(at: $0)}
    }
    
    private func updateVisibleCell(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? NormalNoticeItemCell {
            setUpNormalNoticeCell(cell, forNoticeAt: indexPath)
        } else if let cell = tableView.cellForRow(at: indexPath) as? WarningNoticeItemCell {
            setUpWarningNoticeCell(cell, forNoticeAt: indexPath)
        }
    }
    
    func showProfilePage(for notice: Notice) {
        if let bonus = notice as? BonusNotice,
            let info = bonusEventRepo.event(for: bonus.eventID).info,
            let user = userSession.userFetcherRepo.fetcher(for: info.senderID).user {
            performSegue(withIdentifier: SegueID.showProfile, sender: user)
        } else if let follow = notice as? FollowNotice,
            let user = userSession.userFetcherRepo.fetcher(for: follow.followerID).user {
            performSegue(withIdentifier: SegueID.showProfile, sender: user)
        }
    }
    
    func switchToMyProfile() {
        router.handle(DeepLinks.meTab)
    }
    
    func showGetGemPopUp(for notice: BonusNotice) {
        let event = bonusEventRepo.event(for: notice.eventID)
        guard !event.isRedeemed, let info = event.info else { return }
        var config: GemActionPopUpConfiguration?
        switch info.type {
        case .likePost:
            guard let user = userSession.userFetcherRepo.fetcher(for: info.senderID).user else { return }
            config = LikeFromOfficialNoticePopUpConfiguration(event: event, user: user)
        case .gift:
            guard let user = userSession.userFetcherRepo.fetcher(for: info.senderID).user else { return }
            config = GiftFromOfficialNoticePopUpConfiguration(event: event, user: user)
        case .loginReward:
            config = DailyRewardNoticePopUpConfiguration(event: event)
        }
        config?.mainAction = {[weak self] in
            self?.redeemGemsIfAllowed(for: event)
        }
        performSegue(withIdentifier: SegueID.showPopup, sender: config)
    }
    
}

extension NoticeTableViewController {
    struct SegueID {
        static let showPopup = "showPopup"
        static let showProfile = "showProfile"
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
