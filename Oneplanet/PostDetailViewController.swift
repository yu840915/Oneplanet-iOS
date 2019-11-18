//
//  PostDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostDetailViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var post: Post!
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var moreButtonItem: UIBarButtonItem!
    @IBOutlet weak var reportedPostView: ReportedPostView!
    @IBOutlet weak var scorebarView: ScoreBarView!
    @IBOutlet weak var contentView: UIScrollView!
    @IBOutlet weak var adminView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    
    private var galleryDataSource: PostPhotoGalleryDataSource?
    private var deletePostOperation: DeletePostOperation?
    var canShowAuthorProfile = true
    private var hidingUpdateHandle: Any?
    private var likePostOperation: LikePostOperation?
    private var changePinOperation: ChangePinOperation?
    private var getPostOperation: GetPostOperation?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.titles.photo
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        avatarView.isUserInteractionEnabled = canShowAuthorProfile
        avatarView.action = {[weak self] in
            self?.showProfileForAuthor()
        }
        updateViews(with: post)
        hidingUpdateHandle = userSession.hiddenPosts.didUpdateHandlers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateViewsForIsHidden()
            }
        }
        if userSession.isAdmin && post.authorID != userSession.profile?.id {
            adminView.isHidden = false
        } else {
            adminView.isHidden = true
        }
        updateViewsForIsHidden()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController, nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    func updateViewsForIsHidden() {
        if userSession.hiddenPosts.isHidden(post) {
            reportedPostView.isHidden = false
            contentView.isHidden = true
        } else {
            reportedPostView.isHidden = true
            contentView.isHidden = false
        }
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showMoreActionSheet(_ sender: UIBarButtonItem) {
        let isMine = post.authorID == userSession.profile?.id
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if isMine {
            sheet.addAction(UIAlertAction(title: Localized.titles.edit, style: .default, handler: { (_) in
                self.editPost()
            }))
            sheet.addAction(UIAlertAction(title: Localized.titles.delete, style: .destructive, handler: { (_) in
                self.deletePost()
            }))
        } else {
            sheet.addAction(UIAlertAction(title: Localized.titles.report, style: .destructive, handler: { (_) in
                self.reportPost()
            }))
        }
        if userSession.isAdmin {
            let sticky = post.sticky == true
            if sticky {
                sheet.addAction(UIAlertAction(title: "Unpin", style: .default, handler: {[weak self] (_) in
                    self?.unpin()
                }))
            } else {
                sheet.addAction(UIAlertAction(title: "Pin to Top", style: .default, handler: {[weak self] (_) in
                    self?.pin()
                }))
            }
        }
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func unhidePost(_ sender: Any) {
        userSession.hiddenPosts.unhide(post)
    }
    
    @IBAction func likePost(_ sender: Any) {
        guard userSession.isAdmin && !post.liked && likePostOperation == nil else {
            return
        }
        let op = LikePostOperation(post: post, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLikePost()
            }
        }
        likePostOperation = op
        op.start()
    }
    
    private func didLikePost() {
        let op = likePostOperation!
        likePostOperation = nil
        if op.success == true {
            refresh()
            userSession.notifyPostListUpdate()
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    func showAlert(with error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func refresh() {
        guard getPostOperation == nil else { return }
        let op = GetPostOperation(postID: post.id, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didRefresh()
            }
        }
        getPostOperation = op
        op.start()
    }
    
    func didRefresh() {
        let op = getPostOperation!
        getPostOperation = nil
        if let post = op.post {
            self.post = post
            updateViews(with: post)
        } else {
            logger.error("Cannot refresh post, error: \(op.error)")
        }
    }
    
    func updateViews(with post: Post) {
        likeButton.isEnabled = !post.liked
        updateViews(with: PostCardViewModel(post: post, userSession: userSession))
    }
    
    func updateViews(with dataSource: PostDisplayable) {
        pageControl.isHidden = !dataSource.shouldShowPageControl
        avatarView.avatar = dataSource.avatar
        avatarView.backgrondImage = dataSource.alien?.race.frameImage
        nameLabel.text = dataSource.nickname
        dateLabel.text = dataSource.formatedDate
        if let score = dataSource.relativeScore {
            scorebarView.isHidden = false
            scorebarView.value = score
        } else {
            scorebarView.isHidden = true
        }
        setUpContentSection(with: dataSource)
        let ds = PostPhotoGalleryDataSource(photos: dataSource.photos, collectionView: galleryCollectionView)
        galleryDataSource = ds
        galleryCollectionView.contentOffset = .zero
        galleryCollectionView.reloadData()
        ds.pageControl = pageControl
    }

    private func setUpContentSection(with dataSource: PostDisplayable) {
        contentTextView.isHidden = !dataSource.shouldShowContentSection
        guard dataSource.shouldShowContentSection else {
            return
        }
        let content = dataSource.nickname + " " + dataSource.message
        let nameRange = (content as NSString).range(of: dataSource.nickname)
        let attrStr = NSMutableAttributedString(string: content, attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor: ColorPalette.defaultText])
        attrStr.addAttributes([.font : UIFont.systemFont(ofSize: 14, weight: .semibold)], range: nameRange)
        contentTextView.attributedText = attrStr
    }
   
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? UserProfileViewController {
            vc.profile = (sender as! User)
        }
        if let nav = segue.destination as? UINavigationController {
            if let vc = nav.viewControllers.first as? UserSessionDepending {
                vc.userSession = userSession
            }
            if let vc = nav.viewControllers.first as? ReportReasonPickerTableViewController {
                vc.flowController = (sender as! ReportFlowController)
            } else if let vc = nav.viewControllers.first as? PostCreationFlowViewController {
                vc.postDraft = PostDraft(post: (sender as! Post))
                vc.didPublish = {[weak self] post in
                    self?.handlePostUpdate(post)
                }
            }
        }
    }
}

private extension PostDetailViewController {
    func handlePostUpdate(_ post: Post?) {
        if let post = post {
            self.post = post
            updateViews(with: post)
        }
    }
    
    func showProfileForAuthor() {
        if canShowAuthorProfile,
            let user = userSession.userFetcherRepo.fetcher(for: post.authorID).user {
            performSegue(withIdentifier: SegueID.showProfile, sender: user)
        }
    }
    
    func editPost() {
        guard post.authorID == userSession.profile?.id else { return }
        performSegue(withIdentifier: SegueID.showPostEditor, sender: post)
    }
    
    func deletePost() {
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
        if op.success == true {
            if let nav = navigationController,
                nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
        } else if let error = op.error {
            let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func reportPost() {
        performSegue(withIdentifier: SegueID.showReportFlow, sender: PostReportFlowController(post: post, session: userSession))
    }
    
    func changePin() {
        guard userSession.isAdmin else {return}
    }
    
    func pin() {
        changePin(true)
    }
    
    func unpin() {
        changePin(false)
    }
    
    func changePin(_ isPinning: Bool) {
        guard userSession.isAdmin && changePinOperation == nil else { return }
        let op = ChangePinOperation(post: post, session: userSession, isPinning: isPinning)
        op.completionBlock = {[weak self] in
            self?.didChangePin()
        }
        changePinOperation = op
        op.start()
    }
    
    func didChangePin() {
        let op = changePinOperation!
        changePinOperation = nil
        if op.success == true {
            refresh()
            userSession.notifyPostListUpdate()
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
}

extension PostDetailViewController {
    struct SegueID {
        static let showDetail = "showDetail"
        static let showReportFlow = "showReportFlow"
        static let showProfile = "showProfile"
        static let showPostEditor = "showPostEditor"
    }
}

class ReportedPostView: UIStackView {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var showPostButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.text = Localized.phrases.thanksForReportingPost
        detailLabel.text = Localized.messages.thanksForReportingPost
        showPostButton.setTitle(Localized.phrases.showPost, for: .normal)
    }
}

class GetPostOperation: AlamofireAPIAccessOperation {
    let postID: String
    let session: UserSession
    private(set) var post: Post?
    
    init(postID: String, session: UserSession) {
        self.postID = postID
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("posts/\(postID)")))
    }
    
    override func processData(with data: Data) throws {
        post = try JSONDecoder.default.decode(Post.self, from: data)
    }
}
