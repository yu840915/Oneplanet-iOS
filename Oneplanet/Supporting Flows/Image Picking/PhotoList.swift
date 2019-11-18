//
//  PhotoList.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Photos
import ModelBlocks

class PhotoList: NSObject {
    private let cachingManage = PHCachingImageManager()
    private var fetchedAssets: PHFetchResult<PHAsset>
    private var accessedItems: [String: PhotoListItem] = [:]
    var preferredThumbnailSize: CGSize = CGSize(width: 256, height: 256)
    let changeObservers = MulticastCallbackNode<(PHFetchResultChangeDetails<PHAsset>)->()>()

    override init() {
        let option = PHFetchOptions()
        option.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchedAssets = PHAsset.fetchAssets(with: option)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    var first: PhotoListItem? {
        return count > 0 ? self[0] : nil
    }
    var count: Int { return fetchedAssets.count }
    subscript(idx: Int) -> PhotoListItem {
        let asset = fetchedAssets[idx]
        if let item = accessedItems[asset.localIdentifier] {
            item.update(asset)
            item.fetchThumbnailIfNeeded(targetSize: preferredThumbnailSize)
            return item
        } else {
            let item = PhotoListItem(asset: asset, cachingManage: cachingManage)
            accessedItems[asset.localIdentifier] = item
            item.fetchThumbnailIfNeeded(targetSize: preferredThumbnailSize)
            return item
        }
    }

}

extension PhotoList: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let change = changeInstance.changeDetails(for: fetchedAssets) else { return }
        fetchedAssets = change.fetchResultAfterChanges
        changeObservers.invokeEach{$0(change)}
    }
}

class PhotoListItem {
    private(set) var thumbnail: UIImage?
    private(set) var asset: PHAsset
    private let cachingManage: PHCachingImageManager
    init(asset: PHAsset, cachingManage: PHCachingImageManager) {
        self.cachingManage = cachingManage
        self.asset = asset
    }
    
    fileprivate func update(_ asset: PHAsset) {
        self.asset = asset
    }
    
    func fetchThumbnailIfNeeded(targetSize: CGSize) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        cachingManage.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) {[weak self] (image, info) in
            if let image = image {
                self?.thumbnail = image
            }
        }
    }
}

class FetchImageOperaion: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var image: UIImage?
    let asset: PHAsset
    let targetSize: CGSize
    private var reqeustID: PHImageRequestID?
    
    init(asset: PHAsset, targetSize: CGSize) {
        self.asset = asset
        self.targetSize = targetSize
    }
    
    override func main() {
        guard !isCancelled else { return }
        switch asset.mediaType {
        case .image: fetchImage()
        default: finish()
        }
    }
    
    override func onCancel() {
        if let id = reqeustID {
            PHImageManager.default().cancelImageRequest(id)
        }
    }
    
    private func fetchImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        reqeustID = PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options
            , resultHandler: {[weak self] (image, info) in
                self?.didFetchImage(image, info: info)
        })
    }
    
    private func didFetchImage(_ image: UIImage?, info: [AnyHashable: Any]?) {
        guard !isCancelled else { return }
        error = info?[PHImageErrorKey] as? Error
        self.image = image
        success = image != nil
        finish()
    }
}
