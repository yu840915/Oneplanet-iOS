//
//  ProductDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher
import MarkdownKit

class ProductDetailViewController: UIViewController, UserSessionDepending {

    var userSession: UserSession!
    var product: Product? {
        didSet {
            if isViewLoaded {
                updateViewsForProductIfNeeded()
            }
        }
    }
    var productQuery: String?

    @IBOutlet weak var accessoryContainer: UIStackView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var contentContainer: UIScrollView!
    @IBOutlet weak var lockView: UIStackView!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    private var markdownParser: MarkdownParser!
    private var featureCheck: BiddingFeatureAccessCheckOperation?
    private var getDetailOperation: GetProductDetailOperation?
    private var previews: [WebImageInfo] = [] {
        didSet {
            updateViewsForPreviews()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        markdownParser = MarkdownParser()
        localizeTitles()
        if product != nil {
            updateViewsForProductIfNeeded()
        } else {
            getProductDetail()
        }
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
    
    @IBAction func retry(_ sender: Any) {
        getProductDetail()
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
        if let vc = segue.destination as? UnlockFlowViewController {
            vc.product = product!
        }
    }
}

private extension ProductDetailViewController {
    func updateViewsForProductIfNeeded() {
        guard let prod = product else { return }
        accessoryContainer.isHidden = true
        contentContainer.isHidden = false
        previews = prod.images
        titleLabel.text = prod.displayName
        detailTextView.attributedText = markdownParser.parse(prod.description)
    }
    
    func getProductDetail() {
        guard getDetailOperation == nil else {return}
        accessoryContainer.isHidden = false
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
        retryButton.isHidden = true
        let op = GetProductDetailOperation(query: productQuery!, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetProductDetail()
            }
        }
        getDetailOperation = op
        op.start()
    }
    
    func didGetProductDetail() {
        let op = getDetailOperation!
        getDetailOperation = nil
        if let prod = op.product {
            product = prod
        } else {
            loadingIndicator.stopAnimating()
            errorLabel.isHidden = false
            retryButton.isHidden = false
            errorLabel.text = op.error?.localizedDescription
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
        retryButton.setTitle(Localized.phrases.tryAgain, for: .normal)
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
