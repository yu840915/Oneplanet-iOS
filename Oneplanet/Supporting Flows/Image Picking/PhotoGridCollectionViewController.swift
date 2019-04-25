//
//  PhotoGridCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "cell"

class PhotoGridCollectionViewController: UICollectionViewController {
    var photoList: PhotoList!
    private var updateClock: UpdateClock?
    var itemSelectionHandler: ((PhotoListItem)->())?
    private var eventRegistrations: [Any]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerEvents()
        updateThumbnailSize()
    }
    
    private func registerEvents() {
        var registrations: [Any] = []
        registrations.append(photoList.changeObservers.add({[weak self] (changes) in
            OperationQueue.main.addOperation {
                self?.update(forChanges: changes)
            }
        }))
        eventRegistrations = registrations
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
    
    private func update(forChanges changes: PHFetchResultChangeDetails<PHAsset>) {
        if changes.hasIncrementalChanges {
            let collectionView = self.collectionView!
            collectionView.performBatchUpdates({
                if let removed = changes.removedIndexes, !removed.isEmpty {
                    collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                }
                if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                    collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                }
                changes.enumerateMoves { fromIndex, toIndex in
                    collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                            to: IndexPath(item: toIndex, section: 0))
                }
            })
        } else {
            collectionView.reloadData()
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
