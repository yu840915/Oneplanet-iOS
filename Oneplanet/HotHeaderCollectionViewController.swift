//
//  HotHeaderCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

private let reuseIdentifier = "cell"

class HotHeaderCollectionViewController: UICollectionViewController, UserSessionDepending, DefaultInstanceFactory {
    
    static func fromDefaultStoryboard() -> HotHeaderCollectionViewController {
        return UIStoryboard(name: "Home", bundle: nil).instantiateViewController(withIdentifier: "HotHeaderCollectionViewController") as! HotHeaderCollectionViewController
    }
    var userSession: UserSession!
    var showDetailAction: ((CollectionItemPreviewing)->())?

    var items: [CollectionItemPreviewing] = [] {
        didSet {
            if isViewLoaded {
                updateSections()
                collectionView.reloadData()
            }
        }
    }
    var sections: [Section] = []
    var shouldScrollToBeginning = false
    private weak var autoScrollTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSections()
    }
    
    private func updateSections() {
        if items.isEmpty {
            sections = []
        } else if items.count == 1 {
            sections = [.body]
        } else {
            sections = [.headPadding, .body, .endPadding]
            shouldScrollToBeginning = true
        }
        setUpAutoScrollTimerIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpAutoScrollTimerIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        autoScrollTimer?.invalidate()
    }
    
    private func setUpAutoScrollTimerIfNeeded() {
        autoScrollTimer?.invalidate()
        guard items.count > 1 else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {[weak self] (_) in
            self?.autoScrollToNextPage()
        }
        autoScrollTimer = timer
    }

    private func autoScrollToNextPage() {
        guard let currentIdx = collectionView.indexPathsForVisibleItems.first else {
            return
        }
        guard sections[currentIdx.section] == .body else { return }
        let nextRow = currentIdx.row.advanced(by: 1)
        let isAtEnd = items.count == nextRow
        let next = isAtEnd ? IndexPath(row: 0, section: 2) : IndexPath(row: nextRow, section: 1)
        collectionView.scrollToItem(at: next, at: .centeredHorizontally, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let size = flowLayout.itemSize
        let expectedSize = collectionView.superview!.bounds.size
        if size != expectedSize {
            OperationQueue.main.addOperation {
                flowLayout.itemSize = expectedSize
                flowLayout.invalidateLayout()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let expectedSize = collectionView.superview!.bounds.size
        let doneSizeAdjustment = (flowLayout.itemSize == expectedSize)
        if shouldScrollToBeginning && doneSizeAdjustment {
            shouldScrollToBeginning = false
            collectionView.scrollToItem(at: IndexPath(row: 0, section: 1), at: .centeredHorizontally, animated: false)
        }
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
        case .headPadding, .endPadding: return 1
        case .body: return items.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoGalleryPageCell
        let item: CollectionItemPreviewing
        switch section {
        case .headPadding: item = items.last!
        case .endPadding: item = items.first!
        case .body: item = items[indexPath.row]
        }
        cell.updateViews(with: item.cover)
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
        showDetailAction?(items[indexPath.row])
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        autoScrollTimer?.invalidate()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        setUpAutoScrollTimerIfNeeded()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard sections.count > 1 else { return }
        let atHead = scrollView.contentOffset.x <= 1
        let atEnd = scrollView.contentOffset.x >= (scrollView.contentSize.width - scrollView.frame.width - 1)
        if atHead {
            let endIdx = IndexPath(row: items.count - 1, section: 1)
            collectionView.scrollToItem(at: endIdx, at: .centeredHorizontally, animated: false)
        } else if atEnd {
            let headIdx = IndexPath(row: 0, section: 1)
            collectionView.scrollToItem(at: headIdx, at: .centeredHorizontally, animated: false)
        }
    }
}

extension HotHeaderCollectionViewController {
    enum Section {
        case headPadding
        case body
        case endPadding
    }
}

