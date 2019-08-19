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
    
    @IBOutlet weak var searchButton: UIButton!
    var userSession: UserSession!
    var posts: [Post] = []
    var postList: PostList!
    var sections: [Section] = [.content, .loading]
    private var listUpdateHandles: [Any]?
    private var expandPostsIDs = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchButton.layer.cornerRadius = 4
        prepareForList()
    }

    @IBAction func reload(_ sender: UIRefreshControl) {
        postList.reload()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .content: return posts.count
        case .loading: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .content:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.postCell, for: indexPath) as! PostCardCell
            setUpPostCell(cell, at: indexPath)
            return cell
        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: ReuseID.loadingCell, for: indexPath)
        }
    }
    
    private func setUpPostCell(_ cell: PostCardCell, at indexPath: IndexPath) {
        let post = posts[indexPath.row]
        cell.expanded = expandPostsIDs.contains(post.id)
        cell.updateViews(with: FakePost())
        cell.moreActions = {[weak self] in
            self?.showMoreAction(for: post)
        }
        cell.mainAction = {[weak self] in
            self?.followAuthor(of: post)
        }
        cell.showDetailAction = {[weak self] in
            self?.expendCell(at: indexPath)
        }
        cell.showProfileAction = {[weak self] in
            self?.showProfile(for: post)
        }
    }
    
    private func expendCell(at indexPath: IndexPath) {
        expandPostsIDs.insert(posts[indexPath.row].id)
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
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
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .content:
            let isLastRow = indexPath.row == (posts.count - 1)
            if isLastRow && postList.hasMore {
                postList.loadMoreIfAllowed()
            }
        case .loading:
            (cell as! LoadingCell).activityIndicator.startAnimating()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        expendCell(at: indexPath)
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
                vc.post = (sender as! Post)
            } else if let vc = nav.viewControllers.first as? ReportReasonPickerTableViewController {
                vc.flowController = (sender as! ReportFlowController)
            }
        }
    }

}

private extension PostFeedTableViewController {
    func prepareForList() {
        var handles = [Any]()
        handles.append(postList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(postList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleFetchFailure(with: error)
            }
        }))
        listUpdateHandles = handles
        postList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        posts = postList.items
        prepareSections()
        updateBackground()
    }
    
    func prepareSections() {
        let hasContent = !posts.isEmpty
        let hasMore = postList.hasMore
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
        if !posts.isEmpty {
            tableView.backgroundView = nil
        } else {
            let view = CommonViewFactory.shared.makeSimpleEmptyView()
            view.titleLabel.text = Localized.emptyMessages.posts
            if let error = error {
                view.detailLabel.text = error.localizedDescription
            }
            tableView.backgroundView = view
        }
    }
}

private extension PostFeedTableViewController {
    func followAuthor(of post: Post) {
        
    }
    
    func unfollowAuthor(of post: Post) {
        
    }
    
    func showProfile(for post: Post) {
//        performSegue(withIdentifier: SegueID.showProfile, sender: post.author)
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
        static let loadingCell = "loadingCell"
    }
    
    enum Section {
        case content
        case loading
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

extension UITableViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        tableView.setContentOffset(.zero, animated: true)
    }
}

class FakePost: PostDisplayable {
    var avatar: WebImageInfo?
    var nickname: String = "Abc 123"
    var formatedDate: String = "1m ago"
    var photos: [WebImageInfo] = [WebImageInfo(url: URL(string: "https://i.imgur.com/lytdJKp.png")!), WebImageInfo(url: URL(string: "https://i.imgur.com/lytdJKp.png")!), WebImageInfo(url: URL(string: "https://i.imgur.com/lytdJKp.png")!)]
    var message: String = "Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content Content iap"
    var relativeScore: Float? = 1.0
}
