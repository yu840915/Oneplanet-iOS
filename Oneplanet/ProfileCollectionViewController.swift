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
    fileprivate var sections: [Section] = [.detail]
    fileprivate var posts: [Any] = []
    private var detailController: ProfileDetailViewController?
    var profile: UserProfileDisplayable! {
        didSet {
            if isViewLoaded {
                detailController?.profile = profile
            }
        }
    }
    var configuration: ProfileDetailViewController.DisplayConfiguration = .forGuest
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSections()
    }
    
    private func updateSections() {
        var result: [Section] = [.detail]
        if posts.isEmpty {
            result.append(.emptyView)
        } else {
            result.append(.posts)
        }
        sections = result
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
        case .detail, .emptyView: return 1
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
            updateViews(inPostCell: cell as! PostThumbnailCell, at: indexPath)
        case .emptyView: break
        }
        return cell
    }
    
    private func updateViews(inDetailCell cell: ProfileContainerCell) {
        if cell.contentViewController == nil {
            prepareContentViewController(for: cell)
        }
        cell.contentViewController?.profile = profile
        cell.contentViewController?.configuration = configuration
    }
    
    private func prepareContentViewController(for cell: ProfileContainerCell) {
        let vc = ProfileDetailViewController.fromDefaultStoryboard()
        vc.userSession = userSession
        addChild(vc)
        cell.setUp(vc)
        vc.didMove(toParent: self)
        detailController = vc
    }
    
    private func updateViews(inPostCell cell: PostThumbnailCell, at indexPath: IndexPath) {
        
    }
    
    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .posts
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return sections[indexPath.section] == .posts
    }

}

extension ProfileCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch sections[indexPath.section] {
        case .detail:
            return CGSize(width: collectionView.bounds.width, height: 485)
        case .emptyView:
            return CGSize(width: collectionView.bounds.width, height: 160)
        case .posts:
            let num: CGFloat = 3
            let totalGap = (num - 1) * (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
            let len = (collectionView.bounds.width - totalGap) / num
            return CGSize(width: len, height: len)
        }
    }
}

extension ProfileCollectionViewController {
    enum Section: String {
        case detail = "detailCell"
        case posts = "postCell"
        case emptyView = "emptyCell"
        
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
}

class EmptyPostListCell: UICollectionViewCell {
    @IBOutlet weak var textLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel.text = Localized.emptyMessages.posts
    }
}
