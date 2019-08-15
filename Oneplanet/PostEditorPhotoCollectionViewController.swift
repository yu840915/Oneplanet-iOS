//
//  PostEditorPhotoCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostEditorPhotoCollectionViewController: UICollectionViewController {
    
    var isEditable: Bool = true {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    var sections: [Section] {
        return isEditable ? [.photo, .add] : [.photo]
    }
    var attachments: [ImageAttachment] = [] {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    var photos: [WebImageInfo] = [] {
        didSet {
            if isViewLoaded {
                collectionView.reloadData()
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .photo: return  isEditable ? attachments.count : photos.count
        case .add: return 1
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: section.reuseID, for: indexPath)
        if section == .photo {
            preparePhotoCell(cell as! PhotoGalleryPageCell, at: indexPath)
        }
        return cell
    }
    
    private func preparePhotoCell(_ cell: PhotoGalleryPageCell, at indexPath: IndexPath) {
        if isEditable {
            cell.updateViews(with: attachments[indexPath.row])
        } else {
            cell.updateViews(with: photos[indexPath.row])
        }
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return isEditable
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension PostEditorPhotoCollectionViewController {
    struct ReuseID {
        static let photoCell = "photoCell"
        static let addCell = "addCell"
    }
    
    enum Section {
        case photo, add
        var reuseID: String {
            switch self {
            case .photo: return ReuseID.photoCell
            case .add: return ReuseID.addCell
            }
        }
    }
}
