//
//  FollowingListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class FollowingListTableViewController: UITableViewController, DefaultInstanceFactory, UserSessionDepending {
    
    class func fromDefaultStoryboard() -> FollowingListTableViewController {
        return UIStoryboard(name: "Me", bundle: nil).instantiateViewController(withIdentifier: "FollowingListTableViewController") as! FollowingListTableViewController
    }

    var userList: UserList!
    var userSession: UserSession!
    var users: [User] = []
    var sections: [Section] = []
    var configuration: Configuration = Configuration()
    var updateClock: UpdateClock!
    
    private var listUpdateHandles: [Any]?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareForList()
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updateVisibleContentCells()
        })
    }

    @IBAction func reload(_ sender: UIRefreshControl) {
        userList.reload()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .content: return users.count
        case .loading: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        let cell = tableView.dequeueReusableCell(withIdentifier: section.reuseID, for: indexPath)
        switch section {
        case .content:
            prepareContentCell(cell as! UserOverviewCell, at: indexPath)
        case .loading: break
        }
        return cell
    }
    
    private func prepareContentCell(_ cell: UserOverviewCell, at indexPath: IndexPath) {
        let user = users[indexPath.row]
        cell.updateViews(with: FriendshipOverviewModel(profile: user))
        cell.action = {[weak self] in
            self?.changeFriendship(for: user)
        }
    }
    
    func updateVisibleContentCells() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        indexPaths.forEach{
            if sections[$0.section] == .content,
                let cell = tableView.cellForRow(at: $0) as? UserOverviewCell {
                updateContentCell(cell, at: $0)
            }
        }
    }
    
    func updateContentCell(_ cell: UserOverviewCell, at indexPath: IndexPath) {
        cell.updateViews(with: userSession.socialRelationshipRepo.relationshipWithUser(of: users[indexPath.row].id))
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .content
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: SegueID.showProfile, sender: users[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .content:
            let isLastRow = indexPath.row == (users.count - 1)
            if isLastRow && userList.hasMore {
                userList.loadMoreIfAllowed()
            }
        case .loading:
            (cell as! LoadingCell).activityIndicator.startAnimating()
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserProfileViewController {
            vc.userSession = userSession
            vc.profile = (sender as! User)
        }
    }

}
private extension FollowingListTableViewController {
    func prepareForList() {
        var handles = [Any]()
        handles.append(userList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(userList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        listUpdateHandles = handles
        userList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        users = userList.items
        prepareSections()
        updateBackground()
    }
    
    func prepareSections() {
        let hasContent = !users.isEmpty
        let hasMore = userList.hasMore
        var val: [Section] = [.content]
        if hasContent && hasMore {
            val.append(.loading)
        }
        sections = val
        tableView.reloadData()
    }
    
    func handleFetchFailure(with error: Error?) {
        refreshControl?.endRefreshing()
        updateBackground(with: error)
    }
    
    func updateBackground(with error: Error? = nil) {
        if !users.isEmpty {
            tableView.backgroundView = nil
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            view.titleLabel.text = configuration.emptyMessage
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            tableView.backgroundView = view
        }
    }
    
    func changeFriendship(for user: User) {
        guard let rel = userSession.socialRelationshipRepo.relationshipWithUser(of: user.id),
            let states = rel.states else {
            return
        }
        if states.isBlocking {
            
        } else if states.isFollowing {
            rel.unfollow()
        } else {
            rel.follow()
        }
    }
}

extension FollowingListTableViewController {
    enum Section: String {
        case content = "cell"
        case loading = "loadingCell"
        var reuseID: String {
            return rawValue
        }
    }

    struct SegueID {
        static let showProfile = "showProfile"
    }

}
extension FollowingListTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: title ?? "")
    }
}

extension FollowingListTableViewController {
    class Configuration {
        static let forFollowerList: Configuration = FollowerListConfiguration()
        static let forFollowingList: Configuration = FollowingListConfiguration()
        var emptyMessage: String {
            return ""
        }
    }
    
    class FollowerListConfiguration: Configuration {
        override var emptyMessage: String {
            return Localized.emptyMessages.followerList
        }
    }

    class FollowingListConfiguration: Configuration {
        override var emptyMessage: String {
            return Localized.emptyMessages.followingList
        }
    }
}
