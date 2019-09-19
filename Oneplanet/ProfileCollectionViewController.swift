//
//  ProfileCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/13.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class ProfileCollectionViewController: UICollectionViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var postList: PostList!
    var followCounts: FollowCounts? {
        didSet {
            if isViewLoaded {
                detailController?.followCountsProvider = followCounts
            }
        }
    }
    var relationshipState: SocialRelationshipStates? {
        didSet {
            if isViewLoaded {
                detailController?.relationshipState = relationshipState
            }
        }
    }
    fileprivate var sections: [Section] = [.detail]
    fileprivate var posts: [Post] = []
    private var detailController: ProfileDetailViewController?
    var refreshControl: UIRefreshControl!
    var showFollowListAction: ((URL)->())?
    var showPostDetailAction: ((Post)->())?
    var profile: UserProfileDisplayable! {
        didSet {
            if isViewLoaded {
                detailController?.profile = profile
            }
        }
    }
    var configuration: ProfileDetailViewController.DisplayConfiguration = .forGuest
    var shouldShowWarning = false {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    private var listUpdateHandles: [Any]?
    private var isVisible = false
    private var needsUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let control = UIRefreshControl()
        control.tintColor = .white
        control.addTarget(self, action: #selector(reload(_:)), for: .valueChanged)
        collectionView.addSubview(control)
        refreshControl = control
        prepareForList()
    }

    func setNeedsRefresh() {
        if isVisible {
            postList.reload()
        } else {
            needsUpdate = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true
        if needsUpdate {
            needsUpdate = false
            postList.reload()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        isVisible = false
    }

    @IBAction func reload(_ sender: UIRefreshControl) {
        postList.reload()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .detail, .emptyView, .loading: return 1
        case .posts: return posts.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.reuseID, for: indexPath)
    
        switch section {
        case .detail:
            updateViews(inDetailCell: cell as! ProfileContainerCell)
        case .posts:
            updateViews(inPostCell: cell as! PhotoGalleryPageCell, at: indexPath)
        case .emptyView, .loading: break
        }
        return cell
    }
    
    private func updateViews(inDetailCell cell: ProfileContainerCell) {
        if cell.contentViewController == nil {
            prepareContentViewController(for: cell)
        }
        cell.contentViewController?.profile = profile
        cell.contentViewController?.shouldShowWarning = shouldShowWarning
        cell.contentViewController?.configuration = configuration
    }
    
    private func prepareContentViewController(for cell: ProfileContainerCell) {
        let vc = ProfileDetailViewController.fromDefaultStoryboard()
        vc.userSession = userSession
        vc.showFollowListAction = {[weak self] url in
            self?.showFollowListAction?(url)
        }
        addChild(vc)
        cell.setUp(vc)
        vc.didMove(toParent: self)
        vc.followCountsProvider = followCounts
        detailController = vc
    }
    
    private func updateViews(inPostCell cell: PhotoGalleryPageCell, at indexPath: IndexPath) {
        cell.updateViews(with: posts[indexPath.row].images[0])
    }
    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        switch section {
        case .posts:
            let isLastRow = indexPath.row == (posts.count - 1)
            if isLastRow && postList.hasMore {
                postList.loadMoreIfAllowed()
            }
        case .loading:
            (cell as! LoadingCollectionViewCell).activityIndicator.startAnimating()
        case .emptyView, .detail: break
        }

    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .posts
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .posts
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard sections[indexPath.section] == .posts else { return }
        showPostDetailAction?(posts[indexPath.row])
    }
}

extension ProfileCollectionViewController {
    func prepareForList() {
        var handles = [Any]()
        handles.append(postList.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        })
        handles.append(postList.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleListUpdate()
            }
        }))
        listUpdateHandles = handles
        postList.reload()
    }
    
    func handleListUpdate() {
        refreshControl?.endRefreshing()
        posts = postList.items
        prepareSections()
    }

    func prepareSections() {
        let hasContent = !posts.isEmpty
        let hasMore = postList.hasMore
        var val: [Section] = [.detail]
        if hasContent {
            val.append(.posts)
        } else {
            val.append(.emptyView)
        }
        if hasContent && hasMore {
            val.append(.loading)
        }
        sections = val
        collectionView.reloadData()
    }

}

extension ProfileCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch sections[indexPath.section] {
        case .detail:
            let h = shouldShowWarning ? ProfileDetailViewController.warningHeight : ProfileDetailViewController.baseHeight
            return CGSize(width: collectionView.bounds.width, height: h)
        case .emptyView:
            return CGSize(width: collectionView.bounds.width, height: 160)
        case .posts:
            let num: CGFloat = 3
            let totalGap = (num - 1) * (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
            let len = (collectionView.bounds.width - totalGap) / num
            return CGSize(width: len, height: len)
        case .loading:
            return CGSize(width: collectionView.bounds.width, height: 60)
        }
    }
}

extension ProfileCollectionViewController {
    enum Section: String {
        case detail = "detailCell"
        case posts = "postCell"
        case emptyView = "emptyCell"
        case loading = "loadingCell"
        
        var reuseID: String { return rawValue }
    }
}

class ProfileContainerCell: UICollectionViewCell {
    @IBOutlet weak var containerView: UIView!
    
    private(set) weak var contentViewController: ProfileDetailViewController?
    private var shouldAddConstraintsForContent = false

    func setUp(_ controller: ProfileDetailViewController) {
        guard contentViewController == nil else {
            return
        }
        contentViewController = controller
        containerView.addSubview(controller.view)
        shouldAddConstraintsForContent = true
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        if shouldAddConstraintsForContent,
            let content = contentViewController?.view {
            content.translatesAutoresizingMaskIntoConstraints = false
            let views = ["content": content]
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
            shouldAddConstraintsForContent = false
        }
        super.updateConstraints()
    }
}

class PostThumbnailCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func updateViews(with dataSource: PostDisplayable) {
        
    }
}

class EmptyPostListCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.text = Localized.emptyMessages.posts
    }
}
