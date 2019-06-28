//
//  ProductDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher

class ProductDetailViewController: UIViewController, UserSessionDepending {

    var userSession: UserSession!
    @IBOutlet weak var lockView: UIStackView!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    private var featureCheck: BiddingFeatureAccessCheckOperation?
    private var previews: [WebImageInfo] = [] {
        didSet {
            updateViewsForPreviews()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        updateViewsForPreviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController,
            nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        }
    }
    
    @IBAction func unlockIfAllowed(_ sender: UIButton) {
        guard featureCheck == nil else { return }
        let op = BiddingFeatureAccessCheckOperation(userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleCheckResultAndUnlockIfAllowed()
            }
        }
        featureCheck = op
        op.start()
    }
    
    func handleCheckResultAndUnlockIfAllowed() {
        let op = featureCheck!
        featureCheck = nil
        guard op.isAccessible else { return }
        performSegue(withIdentifier: SegueID.enterUnlockFlow, sender: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
    }

}

extension ProductDetailViewController {
    struct SegueID {
        static let enterUnlockFlow = "enterUnlockFlow"
    }
}

extension ProductDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previews.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! ImageGalleryPageCell
        cell.updateViews(with: previews[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: view.frame.width)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int((scrollView.contentOffset.x / scrollView.frame.width).rounded(.toNearestOrAwayFromZero))
    }
}

private extension ProductDetailViewController {
    func updateViewsForPreviews() {
        pageControl.isHidden = previews.count < 2
        pageControl.numberOfPages = previews.count
        galleryCollectionView.reloadData()
    }
    
    func localizeTitles() {
        title = Localized.phrases.bidLot
        updateViewsForLockState()
    }
    
    func updateViewsForLockState() {
        let isLocked = true
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        lockLabel.text = appearance.title
        lockLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }

}

class ImageGalleryPageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func updateViews(with imageInfo: WebImageInfo) {
        imageView.kf.setImage(with: imageInfo.url)
    }
}
