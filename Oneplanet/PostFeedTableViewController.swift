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
    }
    
    private func showMoreAction(for post: Post) {
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: SegueID.showDetail, sender: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

extension PostFeedTableViewController {
    struct ReuseID {
        static let postCell = "postCell"
        static let reportedPostCell = "reportedPostCell"
        
    }
    struct SegueID {
        static let showDetail = "showDetail"
    }
}

extension PostFeedTableViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: title ?? "")
    }
}

class Post {
    
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
