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
    
    private var galleryDataSource: PostPhotoGalleryDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.titles.photo
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        avatarView.action = {[weak self] in
            self?.showProfileForAuthor()
        }
        updateViews(with: FakePost())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController, nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showMoreActionSheet(_ sender: UIBarButtonItem) {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Localized.titles.edit, style: .default, handler: { (_) in
            self.editPost()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.report, style: .destructive, handler: { (_) in
            self.reportPost()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    func updateViews(with dataSource: PostDisplayable) {
        pageControl.isHidden = !dataSource.shouldShowPageControl
        avatarView.avatar = dataSource.avatar
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
            }
        }
    }
}

private extension PostDetailViewController {
    func showProfileForAuthor() {
        performSegue(withIdentifier: SegueID.showProfile, sender: post.author)
    }
    
    func editPost() {
        
    }
    
    func reportPost() {
        performSegue(withIdentifier: SegueID.showReportFlow, sender: PostReportFlowController())
    }
    

}

extension PostDetailViewController {
    struct SegueID {
        static let showDetail = "showDetail"
        static let showReportFlow = "showReportFlow"
        static let showProfile = "showProfile"
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
