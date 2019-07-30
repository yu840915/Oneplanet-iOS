//
//  PostFeedTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/25.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostFeedTableViewController: UITableViewController, DefaultInstanceFactory, UserSessionDepending {
    
    class func fromDefaultStoryboard() -> PostFeedTableViewController {
        return UIStoryboard(name: "Post", bundle: nil).instantiateViewController(withIdentifier: "PostFeedTableViewController") as! PostFeedTableViewController
    }

    var userSession: UserSession!
    var posts: [Post] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        posts = [Post(), Post(), Post(), Post(), Post()]
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.postCell, for: indexPath) as! PostCardCell
        setUpPostCell(cell, at: indexPath)
        return cell
    }
    
    private func setUpPostCell(_ cell: PostCardCell, at indexPath: IndexPath) {
        let post = posts[indexPath.row]
        cell.updateViews(with: FakePost())
        cell.moreActions = {[weak self] in
            self?.showMoreAction(for: post)
        }
        cell.mainAction = {[weak self] in
            self?.followAuthor(of: post)
        }
        cell.showDetailAction = {[weak self] in
            self?.showDetail(for: post)
        }
        cell.showProfileAction = {[weak self] in
            self?.showProfile(for: post)
        }
    }
    
    private func showMoreAction(for post: Post) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Localized.titles.edit, style: .default, handler: { (_) in
                self.edit(post)
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.report, style: .destructive, handler: { (_) in
            self.report(post)
        }))
        sheet.addAction(UIAlertAction(title: Localized.phrases.unfollow, style: .destructive, handler: { (_) in
            self.unfollowAuthor(of: post)
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showDetail(for: posts[indexPath.row])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController {
            if let vc = nav.viewControllers.first as? UserSessionDepending {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? UserProfileViewController {
                vc.profile = (sender as! User)
            } else if let vc = nav.viewControllers.first as? PostDetailViewController {
                
            } else if let vc = nav.viewControllers.first as? ReportReasonPickerTableViewController {
                vc.flowController = (sender as! ReportFlowController)
            }
        }
    }

}

private extension PostFeedTableViewController {
    func showDetail(for post: Post) {
        performSegue(withIdentifier: SegueID.showDetail, sender: post)
    }
    
    func followAuthor(of post: Post) {
        
    }
    
    func unfollowAuthor(of post: Post) {
        
    }
    
    func showProfile(for post: Post) {
        performSegue(withIdentifier: SegueID.showProfile, sender: post.author)
    }
    
    func edit(_ post: Post) {
        
    }
    
    func report(_ post: Post) {
        performSegue(withIdentifier: SegueID.showReportFlow, sender: PostReportFlowController())
    }
}

extension PostFeedTableViewController {
    struct ReuseID {
        static let postCell = "postCell"
        static let reportedPostCell = "reportedPostCell"
    }
    
    struct SegueID {
        static let showDetail = "showDetail"
        static let showReportFlow = "showReportFlow"
        static let showProfile = "showProfile"
    }
}

extension PostFeedTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: title ?? "")
    }
}

class Post {
    let author: User = User(id: "123", displayID: "Mike 123", nickname: "Mike", character: CharacterOptions.shared.character(for: .one, color: .blue))
}

extension UITableViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
}

class FakePost: PostDisplayable {
    var avatar: WebImageInfo?
    var nickname: String = "Abc 123"
    var formatedDate: String = "1m ago"
    var photos: [WebImageInfo] = [WebImageInfo(url: URL(string: "https://i.imgur.com/lytdJKp.png")!)]
    var message: String = "Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Contenta"
    var relativeScore: Float? = 0.5
}
