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
    private var hidingSignalProducer: TabbarHidingSignalProducer?
    var expectedTabbarFrame: CGRect = .zero
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpNavigationItems()
        (collectionViewLayout as! UICollectionViewFlowLayout).sectionHeadersPinToVisibleBounds = true
    }
    
    private func setUpNavigationItems() {
        let alien = HotNavigationItemView.forAlien()
        let events = HotNavigationItemView.forEvents()
        let news = HotNavigationItemView.forNews()
        news.action = {[weak self] in
            self?.showPromoPopUp()
        }
        navigationItem.rightBarButtonItems = [
            .init(customView: alien),
            .init(customView: events),
            .init(customView: news)
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let producer = TabbarHidingSignalProducer(scrollView: collectionView, halfHidingInterval: (expectedTabbarFrame.height + 20))
        producer.hidingFactorDidChange = {[weak self] in
            self?.moveTabbar()
        }
        producer.animateFactorChange = {[weak self] in
            self?.animateTabbar()
        }
        hidingSignalProducer = producer
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hidingSignalProducer = nil
        tabBarController?.tabBar.transform = .identity
    }
    
    private func moveTabbar() {
        guard let producer = hidingSignalProducer,
            let tabbar = tabBarController?.tabBar else {
            return
        }
        var frame = expectedTabbarFrame
        frame.origin.y += producer.hidingFactor * (frame.height + 20)
        tabbar.frame = frame
    }
    
    private func animateTabbar() {
        guard let producer = hidingSignalProducer,
            let tabbar = tabBarController?.tabBar else {
                return
        }
        var frame = expectedTabbarFrame
        frame.origin.y += producer.hidingFactor * (frame.height + 20)
        UIView.animate(withDuration: 0.15) {
            tabbar.frame = frame
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if expectedTabbarFrame == .zero {
            let rect = tabBarController!.tabBar.frame
            expectedTabbarFrame = CGRect(x: 0, y: rect.origin.y - 20, width: rect.width, height: rect.height + 20)
            tabBarController!.tabBar.frame = expectedTabbarFrame
        }
    }
    
    private func showPromoPopUp() {
        let op = FeatureAccessCheckOperation(userSession: userSession)
        op.start()
        if op.isAccessible {
            performSegue(withIdentifier: SegueID.showPromoPopup, sender: nil)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
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
    struct SegueID {
        static let showPromoPopup = "showPromoPopup"
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

class TabbarHidingSignalProducer {
    let scrollView: UIScrollView
    let halfHidingInterval: CGFloat
    private(set) var hidingFactor: CGFloat = 0
    var hidingFactorDidChange: (()->())?
    var animateFactorChange: (()->())?
    private var eventHandles: [Any]?
    private var startingOffset: InitialCondition?
    private weak var inertiaTimer: Timer?
    private var isDragging: Bool {
        didSet {
            if oldValue != isDragging {
                if isDragging {
                    handleStartDragging()
                } else {
                    handleEndDragging()
                }
            }
        }
    }
    private var draggingWatcher: UpdateClock!
    
    init(scrollView: UIScrollView, halfHidingInterval: CGFloat) {
        self.scrollView = scrollView
        self.halfHidingInterval = halfHidingInterval
        isDragging = scrollView.isTracking
        draggingWatcher = UpdateClock(preferredFrameRate: 30, onTick: {[weak self] in
            self?.updateDragging()
        })
        setUpEventHandles()
    }
    
    private func setUpEventHandles() {
        var handles: [Any] = []
        handles.append(scrollView.observe(\.contentOffset) {[weak self] (scrollView, change) in
            self?.handleDidScroll(change: change)
        })
        eventHandles = handles
    }
    
    private func updateDragging() {
        isDragging = scrollView.isTracking
    }
    
    private func handleDidScroll(change: NSKeyValueObservedChange<CGPoint>) {
        isDragging = scrollView.isTracking
        let isAtTop = scrollView.contentOffset.y < 60
        let isAtBottom = (scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.contentOffset.y - scrollView.frame.height) < 5
        if isAtTop {
            updateFactorIfDifferent(0, animated: true)
            return
        } else if isAtBottom {
            updateFactorIfDifferent(1, animated: true)
            return
        }
        guard scrollView.isTracking || inertiaTimer != nil else { return }
        if let condition = startingOffset {
            var relD = (scrollView.contentOffset.y - condition.offset.y) / halfHidingInterval
            if condition.factor > 0 {
               relD = condition.factor + relD
            }
            updateFactorIfDifferent(max(0, min(1, relD)), animated: false)
        } else {
            startingOffset = InitialCondition(offset: scrollView.contentOffset, factor: hidingFactor)
        }
    }
    
    private func updateFactorIfDifferent(_ factor: CGFloat, animated: Bool) {
        guard hidingFactor != factor else { return }
        hidingFactor = factor
        if animated {
            let handler = animateFactorChange ?? hidingFactorDidChange
            handler?()
        } else {
            hidingFactorDidChange?()
        }
    }
    
    private func handleStartDragging() {
        inertiaTimer?.invalidate()
        inertiaTimer = nil
    }
    
    private func handleEndDragging() {
        guard hidingFactor != 0 && hidingFactor != 1 else {
            startingOffset = nil
            return
        }
        inertiaTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {[weak self] (_) in
            self?.snapHiddingFactor()
        }
    }
    
    private func snapHiddingFactor() {
        guard let condition = startingOffset else { return }
        inertiaTimer = nil
        startingOffset = nil
        var factor: CGFloat = 0
        if condition.factor > 0 {
            factor = ((condition.offset.y - scrollView.contentOffset.y) > halfHidingInterval / 2) ? 0 : 1
        } else {
            factor = ((scrollView.contentOffset.y - condition.offset.y) > halfHidingInterval / 2) ? 1 : 0
        }
        updateFactorIfDifferent(factor, animated: true)
    }
}

extension TabbarHidingSignalProducer {
    struct InitialCondition {
        let offset: CGPoint
        let factor: CGFloat
    }
}
