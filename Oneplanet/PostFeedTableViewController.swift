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
    private var needsUpdate = false
    private var isVisible = false
    private var updateClock: UpdateClock!
    private var deletePostOperation: DeletePostOperation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchButton.layer.cornerRadius = 4
        searchButton.setTitle(Localized.titles.searchID, for: .normal)
        prepareForList()
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updateVisibleRows()
        })
    }

    @IBAction func reload(_ sender: UIRefreshControl) {
        postList.reload()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
        updateIfNeeded()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }
    
    func setNeedsRefresh() {
        if isVisible {
            postList.reload()
        } else {
            needsUpdate = true
        }
    }
    
    private func updateIfNeeded() {
        if needsUpdate {
            needsUpdate = false
            postList.reload()
        }
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
            let post = posts[indexPath.row]
            if userSession.hiddenPosts.isHidden(post) {
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.reportedPostCell, for: indexPath) as! ReportedPostCell
                cell.showPostAction = {[weak self] in
                    self?.unhide(post)
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.postCell, for: indexPath) as! PostCardCell
                setUpPostCell(cell, at: indexPath)
                return cell
            }
        case .loading:
            return tableView.dequeueReusableCell(withIdentifier: ReuseID.loadingCell, for: indexPath)
        }
    }
    
    private func setUpPostCell(_ cell: PostCardCell, at indexPath: IndexPath) {
        let post = posts[indexPath.row]
        cell.expanded = expandPostsIDs.contains(post.id)
        cell.updateViews(with: PostCardViewModel(post: post))
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
        updateCell(cell, at: indexPath)
    }
    
    private func updateCell(_ cell: PostCardCell, at indexPath: IndexPath) {
        let post = posts[indexPath.row]
        cell.updateViews(with: userSession.userFetcherRepo.fetcher(for: post.authorID))
        if let rel = userSession.socialRelationshipRepo.relationshipWithUser(of: post.authorID)?.states {
            cell.actionButton.isHidden = rel.isFollowing
        } else {
            cell.actionButton.isHidden = true
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
        let isMine = post.authorID == userSession.profile?.id
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if isMine {
            sheet.addAction(UIAlertAction(title: Localized.titles.edit, style: .default, handler: { (_) in
                self.edit(post)
            }))
            sheet.addAction(UIAlertAction(title: Localized.titles.delete, style: .destructive, handler: { (_) in
                self.deletePost(post)
            }))
        } else  {
            sheet.addAction(UIAlertAction(title: Localized.titles.report, style: .destructive, handler: { (_) in
                self.report(post)
            }))
            if let rel = userSession.socialRelationshipRepo.relationshipWithUser(of: post.authorID)?.states {
                if rel.isFollowing {
                    sheet.addAction(UIAlertAction(title: Localized.phrases.unfollow, style: .destructive, handler: { (_) in
                        self.unfollowAuthor(of: post)
                    }))
                } else {
                    sheet.addAction(UIAlertAction(title: Localized.phrases.follow, style: .default, handler: { (_) in
                        self.followAuthor(of: post)
                    }))
                }

            }
        }
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
        guard sections[indexPath.section] == .content &&
            !userSession.hiddenPosts.isHidden(posts[indexPath.row]) else {
            return
        }
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
            } else if let vc = nav.viewControllers.first as? PostCreationFlowViewController {
                vc.postDraft = PostDraft(post: (sender as! Post))
                vc.didPublish = {[weak self] _ in
                    self?.setNeedsRefresh()
                }
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
        handles.append(userSession.hiddenPosts.didUpdateHandlers.add{[weak self] in
            OperationQueue.main.addOperation {
                self?.tableView.reloadData()
            }
        })
        listUpdateHandles = handles
        postList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        let helper = DeduplicationHelper()
        posts = postList.items.filter{ helper.addIfAllowed($0.id) }
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
    
    func updateVisibleRows() {
        guard let indexPaths = tableView.indexPathsForVisibleRows else { return }
        indexPaths.forEach{
            if sections[$0.section] == .content,
                let cell = tableView.cellForRow(at: $0) as? PostCardCell {
                updateCell(cell, at: $0)
            }
        }
    }
}

private extension PostFeedTableViewController {
    func unhide(_ post: Post) {
        userSession.hiddenPosts.unhide(post)
    }
    
    func followAuthor(of post: Post) {
        guard let rel = userSession.socialRelationshipRepo.relationshipWithUser(of: post.authorID) else {
            return
        }
        rel.follow()
    }
    
    func unfollowAuthor(of post: Post) {
        guard let rel = userSession.socialRelationshipRepo.relationshipWithUser(of: post.authorID) else {
            return
        }
        rel.unfollow()
    }
    
    func showProfile(for post: Post) {
        guard let user = userSession.userFetcherRepo.fetcher(for: post.authorID).user else {
            return
        }
        performSegue(withIdentifier: SegueID.showProfile, sender: user)
    }
    
    func deletePost(_ post: Post) {
        guard deletePostOperation == nil else { return }
        let op = DeletePostOperation(post: post, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didDeletePost()
            }
        }
        deletePostOperation = op
        op.start()
    }
    
    func didDeletePost() {
        let op = deletePostOperation!
        deletePostOperation = nil
        if let error = op.error {
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }

    func edit(_ post: Post) {
        performSegue(withIdentifier: SegueID.showPostEditor, sender: post)
    }
    
    func report(_ post: Post) {
        performSegue(withIdentifier: SegueID.showReportFlow, sender: PostReportFlowController(post: post, session: userSession))
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
        static let showPostEditor = "showPostEditor"
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

class PostCardViewModel: PostDisplayable {
    let avatar: WebImageInfo? = nil
    let nickname: String = ""
    let formatedDate: String
    let photos: [WebImageInfo]
    let message: String
    let relativeScore: Float?
    var alien: Alien? = nil
    
    init(post: Post) {
        photos = post.images
        formatedDate = SharedSpeciaFormatters.dateFromNowForPosts.string(from: post.createdAt)
        message = post.caption
        if let score = post.score,
            post.type == PostType.valued.rawValue {
            relativeScore = Float(score) / 100
        } else {
            relativeScore = nil
        }
    }
}
