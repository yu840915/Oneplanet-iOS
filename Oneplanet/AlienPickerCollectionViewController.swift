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
    
    var characters: [Character] = [] {
        didSet {
            if isViewLoaded {
                updateSections()
                collectionView.reloadData()
            }
        }
    }
    var selectedIndexDidChange: (()->())?
    var preselectedIndex: Int = 0
    private(set) var selectedIndex: Int = 0 {
        didSet {
            if oldValue != selectedIndex {
                selectedIndexDidChange?()
            }
        }
    }
    var sections: [Section] = []
    var shouldScrollToBeginning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.decelerationRate = .fast
        updateSections()
    }

    private func updateSections() {
        if characters.isEmpty {
            sections = []
        } else if characters.count == 1 {
            sections = [.body]
        } else {
            sections = [.headPadding, .body, .endPadding]
            shouldScrollToBeginning = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let doneSizeAdjustment = !characters.isEmpty
        if shouldScrollToBeginning && doneSizeAdjustment {
            shouldScrollToBeginning = false
            collectionView.scrollToItem(at: IndexPath(row: preselectedIndex, section: 1), at: .centeredHorizontally, animated: false)
        }
    }
    
    func scrollToNext() {
        guard collectionView.indexPathsForVisibleItems.count == 3 else { return }
        let nextRow = selectedIndex.advanced(by: 1)
        let isAtEnd = characters.count == nextRow
        let next = isAtEnd ? IndexPath(row: 0, section: 2) : IndexPath(row: nextRow, section: 1)
        collectionView.scrollToItem(at: next, at: .centeredHorizontally, animated: true)
    }
    
    func scrollToPrevious() {
        guard collectionView.indexPathsForVisibleItems.count == 3 else { return }
        let previousRow = selectedIndex.advanced(by: -1)
        let isAtBegin = characters.count == previousRow
        let next = isAtBegin ? IndexPath(row: 1, section: 0) : IndexPath(row: previousRow, section: 1)
        collectionView.scrollToItem(at: next, at: .centeredHorizontally, animated: true)
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .headPadding, .endPadding: return 2
        case .body: return characters.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlienCell
        let character: Character
        switch section {
        case .headPadding: character = characters[characters.endIndex - 2 + indexPath.row]
        case .endPadding, .body: character = characters[indexPath.row]
        }

        cell.imageView.image = character.avatar
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width / 3
        let idx = Int(((scrollView.contentOffset.x) / width).rounded(.toNearestOrAwayFromZero)) - 1
        if idx == -1 {
            selectedIndex = characters.count - 1
        } else if idx == characters.count {
            selectedIndex = 0
        } else {
            selectedIndex = idx
        }
        guard sections.count > 1 else { return }
        let atHead = scrollView.contentOffset.x <= 1
        let atEnd = scrollView.contentOffset.x >= (scrollView.contentSize.width - scrollView.frame.width - 1)
        if atHead {
            let endIdx = IndexPath(row: characters.count - 1, section: 1)
            collectionView.scrollToItem(at: endIdx, at: .centeredHorizontally, animated: false)
        } else if atEnd {
            let headIdx = IndexPath(row: 0, section: 1)
            collectionView.scrollToItem(at: headIdx, at: .centeredHorizontally, animated: false)
        }
    }
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let width = scrollView.frame.width / 3
        let endIdx = ((scrollView.contentOffset.x + targetContentOffset.pointee.x) / (2 * width)).rounded(.toNearestOrAwayFromZero)
        targetContentOffset.pointee.x = endIdx * width
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
        return CGSize(width: collectionView.frame.width / 3, height: collectionView.frame.height)
    }
}

extension AlienPickerCollectionViewController {
    enum Section {
        case headPadding
        case body
        case endPadding
    }
}

class AlienCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
