//
//  AlienPickerCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

class AlienPickerCollectionViewController: UICollectionViewController {
    
    var selectedIndexDidChange: (()->())?
    private(set) var selectedIndex: Int = 0 {
        didSet {
            if oldValue != selectedIndex {
                selectedIndexDidChange?()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.decelerationRate = .fast
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if collectionView.contentInset == .zero {
            let inset = collectionView.superview!.frame.width / 4
            collectionView.contentInset.left = inset
            collectionView.contentInset.right = inset
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlienCell
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width / 2
        let inset = width / 2
        let idx = ((inset + scrollView.contentOffset.x) / width).rounded(.toNearestOrAwayFromZero)
        selectedIndex = Int(idx)
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let width = scrollView.frame.width / 2
        let inset = width / 2
        let endIdx = ((inset + targetContentOffset.pointee.x) / width).rounded(.toNearestOrAwayFromZero)
        targetContentOffset.pointee.x = (endIdx * width) - inset
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

}

extension AlienPickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 2, height: collectionView.frame.height)
    }
}

class AlienCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
