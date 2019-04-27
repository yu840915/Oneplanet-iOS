//
//  WelcomeMessageContentCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/25.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import SwiftGif

private let reuseIdentifier = "cell"

class WelcomeMessageContentCollectionViewController: UICollectionViewController {
    var imageReferences: [ImageReference] = []
    var currentIndexDidChange: (()->())?
    private(set) var currentIndex: Int = 0 {
        didSet {
            if oldValue != currentIndex {
                currentIndexDidChange?()
            }
        }
    }
    
    private var autoScrollTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageReferences.count > 1 {
            let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {[weak self] (_) in
                self?.autoScrollToNextPage()
            }
            autoScrollTimer = timer
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disableAutoScroll()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let size = flowLayout.itemSize
        let expectedSize = CGSize(width: UIScreen.main.bounds.width, height: view.bounds.height)
        if size != expectedSize {
            OperationQueue.main.addOperation {
                flowLayout.itemSize = expectedSize
                flowLayout.invalidateLayout()
            }
        }
    }
    
    private func autoScrollToNextPage() {
        let next = currentIndex.advanced(by: 1)
        let isAtEnd = imageReferences.count == next
        if isAtEnd {
            disableAutoScroll()
        } else {
            collectionView.scrollToItem(at: IndexPath(row: next, section: 0), at: .centeredHorizontally, animated: true)
        }

    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageReferences.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageTileCollectionViewCell
        cell.updateViews(with: imageReferences[indexPath.row])
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        disableAutoScroll()
    }
    
    private func disableAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        currentIndex = Int((scrollView.contentOffset.x / scrollView.frame.width).rounded(.toNearestOrAwayFromZero))
    }
}

class ImageTileCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func updateViews(with ref: ImageReference) {
        if let imgRef = ref as? NativeImageReference {
            imageView.image = imgRef.image
        } else if let gifRef = ref as? GifImageFileReference {
            imageView.loadGif(name: gifRef.fileName)
        }
    }
}

class ImageReference {
    fileprivate init() {}
}

class NativeImageReference: ImageReference {
    let image: UIImage
    init(image: UIImage) {
        self.image = image
    }
}

class GifImageFileReference: ImageReference {
    let fileName: String
    init(fileName: String) {
        self.fileName = fileName
    }
}

