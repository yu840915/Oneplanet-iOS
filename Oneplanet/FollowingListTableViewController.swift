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
    var configuration: Configuration = Configuration()
    
    private var listUpdateHandles: [Any]?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        prepareForList()
    }

    @IBAction func reload(_ sender: UIRefreshControl) {
        userList.reload()
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserOverviewCell
        let user = users[indexPath.row]
        cell.updateViews(with: FriendshipOverviewModel(profile: user))
        cell.action = {[weak self] in
            self?.changeFriendship(for: user)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: SegueID.showProfile, sender: users[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastRow = indexPath.row == (users.count - 1)
        if isLastRow && userList.hasMore {
            userList.loadMoreIfAllowed()
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
        tableView.reloadData()
        updateBackground()
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
        
    }
}

extension FollowingListTableViewController {
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
