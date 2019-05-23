//
//  HotCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class HotCollectionViewController: UICollectionViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var needsUpdateTabar = true
    private var headerController: HotHeaderCollectionViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            .init(customView: HotNavigationItemView.forAlien()),
            .init(customView: HotNavigationItemView.forEvents()),
            .init(customView: HotNavigationItemView.forNews())
        ]
        (collectionViewLayout as! UICollectionViewFlowLayout).sectionHeadersPinToVisibleBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard needsUpdateTabar else { return }
        needsUpdateTabar = false
        let rect = tabBarController!.tabBar.frame
        tabBarController!.tabBar.backgroundColor = .red
        tabBarController!.tabBar.frame = CGRect(x: 0, y: rect.origin.y - 20, width: rect.width, height: rect.height + 20)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseID.cell, for: indexPath) as! HotItemCell
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header =
             collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ReuseID.header, for: indexPath) as! PromotionHeader
            if header.contentViewController == nil {
                prepareContentViewController(for: header)
            }
            return header
        }
        return UICollectionReusableView()
    }

    private func prepareContentViewController(for header: PromotionHeader) {
        let vc = HotHeaderCollectionViewController.fromDefaultStoryboard()
        vc.userSession = userSession
        addChild(vc)
        header.setUp(vc)
        vc.didMove(toParent: self)
        headerController = vc
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

}

extension HotCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let num: CGFloat = 2
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let totalGap = (num - 1) * layout.minimumInteritemSpacing + layout.sectionInset.left + layout.sectionInset.right
        let len = (collectionView.bounds.width - totalGap) / num
        return CGSize(width: len, height: len)
    }

}

extension HotCollectionViewController {
    struct ReuseID {
        static let cell = "cell"
        static let header = "header"
    }
}

class PromotionHeader: UICollectionReusableView {
    @IBOutlet weak var containerView: UIView!
    
    private(set) weak var contentViewController: HotHeaderCollectionViewController?
    private var shouldAddConstraintsForContent = false
    
    func setUp(_ controller: HotHeaderCollectionViewController) {
        guard contentViewController == nil else {
            return
        }
        contentViewController = controller
        containerView.addSubview(controller.view)
        shouldAddConstraintsForContent = true
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        if shouldAddConstraintsForContent,
            let content = contentViewController?.view {
            content.translatesAutoresizingMaskIntoConstraints = false
            let views = ["content": content]
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
            shouldAddConstraintsForContent = false
        }
        super.updateConstraints()
    }
}

class HotItemCell: UICollectionViewCell {
    
}
