//
//  PhotoGridCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

class PhotoGridCollectionViewController: UICollectionViewController {
    var photoList: PhotoList!
    private var updateClock: UpdateClock?
    var itemSelectionHandler: ((PhotoListItem)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateThumbnailSize()
    }

    private func updateThumbnailSize() {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = ((UIScreen.main.bounds.width - 3 * layout.minimumInteritemSpacing) / 4).rounded(.towardZero)
        layout.itemSize = CGSize(width: width, height: width)
        let pixelWidth = UIScreen.main.scale * width
        photoList.preferredThumbnailSize = CGSize(width: pixelWidth, height: pixelWidth)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateClock = UpdateClock(preferredFrameRate: 10, onTick: {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateVisibleCells()
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateClock = nil
    }
    
    private func updateVisibleCells() {
        let indexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            let cell = collectionView.cellForItem(at: indexPath) as! PhotoGridCell
            if cell.imageView.image == nil {
                cell.imageView.image = photoList[indexPath.row].thumbnail
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoGridCell
        cell.imageView.image = photoList[indexPath.row].thumbnail
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        itemSelectionHandler?(photoList[indexPath.row])
    }
}

class PhotoGridCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
}

class UpdateClock {
    private var displayLink: CADisplayLink!
    private var actionTarget: DisplayLinkActionTarget
    
    convenience init(preferredInterval interval: TimeInterval = 1, runloopMode mode: RunLoop.Mode = .common, onTick: @escaping ()->Void) {
        self.init(preferredFrameRate: Int(1.0 / interval), runloopMode: mode, onTick: onTick)
    }
    
    init(preferredFrameRate: Int, runloopMode mode: RunLoop.Mode = .common, onTick: @escaping ()->Void) {
        actionTarget = DisplayLinkActionTarget(tickAction: onTick)
        displayLink = CADisplayLink(target: actionTarget, selector: #selector(DisplayLinkActionTarget.triggerUIUpdate(sender:)))
        displayLink.preferredFramesPerSecond = preferredFrameRate
        displayLink.add(to: .main, forMode: mode)
    }
    
    deinit {
        displayLink.invalidate()
    }
    
}

fileprivate extension UpdateClock {
    
    class DisplayLinkActionTarget {
        
        let tickAction: ()->Void
        
        init(tickAction: @escaping ()->Void) {
            self.tickAction = tickAction
        }
        
        @objc func triggerUIUpdate(sender: Any) {
            tickAction()
        }
        
    }
    
}
