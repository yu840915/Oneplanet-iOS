//
//  BlockListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BlockListTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var users: [User] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.phrases.blockList
        users = [User(id: "123", displayID: "Maker123", nickname: "Mia", character: nil)]
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserOverviewCell
        let user = users[indexPath.row]
        cell.updateViews(with: BlockedUserOverviewModel(profile: user))
        cell.action = {[weak self] in
            self?.showUnblockAlertForUser(at: indexPath)
        }
        cell.actionButton.isSelected = true
        return cell
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
    
    private func unblock(_ user: User) {
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class BlockedUserOverviewModel: UserOverviewDisplayable {
    var avatar: WebImageInfo? {
        return profile.avatar
    }
    var displayName: String {
        return profile.nickname
    }
    var displayID: String {
        return profile.displayID
    }
    var character: Character? {
        return profile.character
    }
    let actionTitle: String = Localized.titles.unblock
    let selectedActionTitle: String? = nil
    
    let profile: UserProfileDisplayable
    
    init(profile: UserProfileDisplayable) {
        self.profile = profile
    }
}
