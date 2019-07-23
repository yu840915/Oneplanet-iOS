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

    var userSession: UserSession!
    var users: [User] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        users = [User(id: "567", displayID: "Momo123", nickname: "Momo", character: nil)]
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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserProfileViewController {
            vc.userSession = userSession
            vc.profile = (sender as! User)
        }
    }

}
private extension FollowingListTableViewController {
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
        return IndicatorInfo(title: Localized.titles.followings)
    }
}
