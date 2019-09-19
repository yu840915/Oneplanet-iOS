//
//  BlockListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BlockListTableViewController: UITableViewController, UserSessionDepending {
    
    var blockList: UserList!
    var userSession: UserSession!
    var users: [User] = []
    var sections: [Section] = []
    private var listUpdateHandles: [Any]?
    var updateClock: UpdateClock!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        title = Localized.phrases.blockList
        prepareList()
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updateVisibleContentCells()
        })
    }
    
    @IBAction func reload(_ sender: UIRefreshControl) {
        blockList.reload()
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
        cell.updateViews(with: BlockedUserOverviewModel(profile: user))
        cell.action = {[weak self] in
            self?.showUnblockAlertForUser(at: indexPath)
        }
        cell.actionButton.isSelected = true
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
        if let states = userSession.socialRelationshipRepo.relationshipWithUser(of: users[indexPath.row].id)?.states, states.isBlocking {
            cell.actionButton.isHidden = false
            cell.actionButton.isSelected = true
        } else {
            cell.actionButton.isHidden = true
        }
    }

    private func showUnblockAlertForUser(at indexPath: IndexPath) {
        let user = users[indexPath.row]
        let alert = UIAlertController(title: String(format: Localized.messageFormats.unblockUserPrompt, user.nickname), message: Localized.messages.unblockDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized.titles.unblock, style: .default, handler: { (_) in
            self.unblock(user)
        }))
        present(alert, animated: true, completion: nil)
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
            if isLastRow && blockList.hasMore {
                blockList.loadMoreIfAllowed()
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
extension BlockListTableViewController {
    func prepareList() {
        blockList = UserList.blockList(with: userSession)
        var handles = [Any]()
        handles.append(blockList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(blockList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        listUpdateHandles = handles
        blockList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        users = blockList.items
        prepareSections()
        updateBackground()
    }
    
    func prepareSections() {
        let hasContent = !users.isEmpty
        let hasMore = blockList.hasMore
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
            view.titleLabel.text = Localized.emptyMessages.blockList
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            tableView.backgroundView = view
        }
    }
    
    func unblock(_ user: User) {
        
    }
}

extension BlockListTableViewController {
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

class BlockedUserOverviewModel: UserOverviewDisplayable {
    var avatar: WebImageInfo? {
        return profile.avatar
    }
    var displayName: String {
        return profile.nickname
    }
    var username: String {
        return profile.username
    }
    var character: Alien? {
        return profile.alien
    }
    let actionTitle: String = Localized.titles.unblock
    let selectedActionTitle: String? = nil
    
    let profile: UserProfileDisplayable
    
    init(profile: UserProfileDisplayable) {
        self.profile = profile
    }
}
