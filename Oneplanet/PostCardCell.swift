//
//  PostCardCell.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher

protocol PostDisplayable {
    var avatar: WebImageInfo? {get}
    var nickname: String {get}
    var formatedDate: String {get}
    var photos: [WebImageInfo] {get}
    var message: String {get}
    var relativeScore: Float? {get}
    var alien: Alien? {get}
}

extension PostDisplayable {
    var shouldShowPageControl: Bool {
        return photos.count > 1
    }
    var shouldShowContentSection: Bool {
        return !message.isEmpty
    }
}

class PostCardCell: UITableViewCell {
    var mainAction: (()->())?
    var moreActions: (()->())?
    var showProfileAction: (()->())?
    var showDetailAction: (()->())?
    var likeAction: (()->())?
    
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var moreActionButton: UIButton!
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contentTextView: UITextView!
    
    @IBOutlet weak var adminView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var expandedContentTextView: UITextView!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var layoutTextView: UITextView!
    @IBOutlet weak var scoreBarView: ScoreBarView!
    
    private var galleryDataSource: PostPhotoGalleryDataSource?
    var expanded: Bool = false {
        didSet {
            updateViewForExpanded()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layoutTextView.textContainer.lineBreakMode = .byWordWrapping
        contentTextView.textContainer.maximumNumberOfLines = 3
        contentTextView.textContainer.lineBreakMode = .byTruncatingTail
        actionButton.setTitle(Localized.phrases.follow, for: .normal)
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
        avatarView.action = {[weak self] in
            self?.showProfileAction?()
        }
    }
    
    func updateViewForExpanded() {
        contentTextView.isHidden = expanded
        expandedContentTextView.isHidden = !expanded
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if expanded || contentTextView.isHidden {
            moreButton.isHidden = true
            return
        }
        if contentTextView.textContainer.exclusionPaths.isEmpty {
            setNeedsLayout()
        } else {
            let differentHeight = layoutTextView.frame.height > contentTextView.frame.height
            let differentUnlaidChar = layoutTextView.layoutManager.firstUnlaidCharacterIndex() != contentTextView.layoutManager.firstUnlaidCharacterIndex()
            let showMore = differentHeight || differentUnlaidChar
            moreButton.isHidden = !showMore
        }
        let w = moreButton.bounds.width
        let x = contentTextView.bounds.width - w
        contentTextView.textContainer.exclusionPaths = [UIBezierPath(rect: CGRect(x: x, y: 45, width: w, height: 10))]
        layoutTextView.textContainer.exclusionPaths = [UIBezierPath(rect: CGRect(x: x, y: 45, width: w, height: 10))]
    }
    
    @IBAction func invokeAction(_ sender: UIButton) {
        mainAction?()
    }
    
    @IBAction func invokeMoreAction(_ sender: UIButton) {
        moreActions?()
    }
    
    @IBAction func invokeShowDetailAction(_ sender: UIButton) {
        showDetailAction?()
    }
    
    @IBAction func invokeLikeAction(_ sender: Any) {
        likeAction?()
    }
}

extension PostCardCell {
    func updateViews(with dataSource: PostDisplayable) {
        pageControl.isHidden = !dataSource.shouldShowPageControl
        avatarView.avatar = dataSource.avatar
        nameLabel.text = dataSource.nickname
        dateLabel.text = dataSource.formatedDate
        setUpContentSection(with: dataSource)
        if let score = dataSource.relativeScore {
            scoreBarView.isHidden = false
            scoreBarView.value = score
        } else {
            scoreBarView.isHidden = true
        }
        let ds = PostPhotoGalleryDataSource(photos: dataSource.photos, collectionView: galleryCollectionView)
        ds.didSelectPhoto = {[weak self] _ in
            self?.showDetailAction?()
        }
        galleryDataSource = ds
        galleryCollectionView.contentOffset = .zero
        galleryCollectionView.reloadData()
        ds.pageControl = pageControl
    }
    
    func updateViews(with userFetcher: UserFetcher) {
        avatarView.update(with: userFetcher.user)
        guard let user = userFetcher.user else {
            userFetcher.initializeIfNeeded()
            return
        }
        nameLabel.text = user.nickname
    }
    
    private func setUpContentSection(with dataSource: PostDisplayable) {
        contentTextView.isHidden = !dataSource.shouldShowContentSection || expanded
        expandedContentTextView.isHidden = !dataSource.shouldShowContentSection || !expanded
        guard dataSource.shouldShowContentSection else {
            return
        }
        let content = dataSource.nickname + " " + dataSource.message
        let nameRange = (content as NSString).range(of: dataSource.nickname)
        let attrStr = NSMutableAttributedString(string: content, attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor: ColorPalette.defaultText])
        attrStr.addAttributes([.font : UIFont.systemFont(ofSize: 14, weight: .semibold)], range: nameRange)
        contentTextView.textContainer.exclusionPaths = []
        layoutTextView.textContainer.exclusionPaths = []
        layoutTextView.alpha = 0
        layoutTextView.attributedText = attrStr
        contentTextView.attributedText = attrStr
        expandedContentTextView.attributedText = attrStr
        contentView.setNeedsLayout()
    }
}

class ReportedPostCell: UITableViewCell {
    var showPostAction: (()->())?
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var showPostButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.text = Localized.phrases.thanksForReportingPost
        detailLabel.text = Localized.messages.thanksForReportingPost
        showPostButton.setTitle(Localized.phrases.showPost, for: .normal)
    }
    
    @IBAction func invokeShowPostAction(_ sender: UIButton) {
        showPostAction?()
    }
}

class PostPhotoGalleryDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    let photos: [WebImageInfo]
    let collectionView: UICollectionView
    var didSelectPhoto: ((WebImageInfo)->())?
    init(photos: [WebImageInfo], collectionView: UICollectionView) {
        self.photos = photos
        self.collectionView = collectionView
        super.init()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    var pageControl: UIPageControl? {
        didSet {
            updatePageControl()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoGalleryPageCell
        cell.updateViews(with: photos[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectPhoto?(photos[indexPath.row])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePageControl()
    }
    
    private func updatePageControl() {
        guard let control = pageControl else { return }
        control.numberOfPages = photos.count
        control.currentPage = Int((collectionView.contentOffset.x / collectionView.frame.width).rounded(.toNearestOrAwayFromZero))
    }
}

class PhotoGalleryPageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = ColorPalette.defaultEmptyBackground
    }
    
    func updateViews(with info: WebImageInfo) {
        imageView.kf.setImage(with: info.url)
    }
    
    func updateViews(with attachement: ImageAttachment) {
        imageView.image = attachement.localImage
    }
}

class ScoreBarView: UIView {
    @IBOutlet weak var barMaskView: UIView!
    @IBOutlet weak var scoreButton: UIButton!
    @IBOutlet weak var scoreBarVisibleLength: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if scoreBarVisibleLength.constant != CGFloat(value) * bounds.width {
            updateScoreBarVisibleLength()
        }
    }
    
    var value: Float = 0 {
        didSet {
            value = .maximum(0, .minimum(1, value))
            updateScoreBarVisibleLength()
        }
    }
    
    func updateScoreBarVisibleLength() {
        scoreBarVisibleLength.constant = CGFloat(value) * bounds.width
        setNeedsLayout()
    }
}
