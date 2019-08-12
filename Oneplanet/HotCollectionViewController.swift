//
//  HotCollectionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class HotCollectionViewController: UICollectionViewController, UserSessionDepending {
    
    var balloonString: UIImageView!
    var userSession: UserSession!
    var needsUpdateTabar = true
    private var headerController: HotHeaderCollectionViewController?
    private var hidingSignalProducer: TabbarHidingSignalProducer?
    var expectedTabbarFrame: CGRect = .zero
    var expectedBalloonStringFrame: CGRect = .zero
    var hotList: HotItemList!
    var bannerList: BannerItemList!
    var updateHandles: [Any]?
    var hotItems: [CollectionItemPreviewing] = []
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        setUpRefreshControl()
        prepareLists()
    }
    
    private func setUpRefreshControl() {
        let control = UIRefreshControl()
        control.tintColor = .white
        control.addTarget(self, action: #selector(reload(_:)), for: .valueChanged)
        collectionView.addSubview(control)
        refreshControl = control
        setUpNavigationItems()
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
        if expectedBalloonStringFrame == .zero {
            expectedBalloonStringFrame = balloonString.frame
        } else {
            animateTabbar()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        hidingSignalProducer = nil
    }
    
    @IBAction func reload(_ sender: UIRefreshControl) {
        hotList.reload()
        bannerList.reload()
    }
    
    private func moveTabbar() {
        guard let producer = hidingSignalProducer,
            let tabbar = tabBarController?.tabBar else {
            return
        }
        var frame = expectedTabbarFrame
        var balloonFrame = expectedBalloonStringFrame
        frame.origin.y += producer.hidingFactor * (frame.height + 20)
        balloonFrame.size.height += producer.hidingFactor * (frame.height + 20)
        tabbar.frame = frame
        balloonString.frame = balloonFrame
    }
    
    private func animateTabbar() {
        guard let producer = hidingSignalProducer,
            let tabbar = tabBarController?.tabBar else {
                return
        }
        var frame = expectedTabbarFrame
        var balloonFrame = expectedBalloonStringFrame
        frame.origin.y += producer.hidingFactor * (frame.height + 20)
        balloonFrame.size.height += producer.hidingFactor * (frame.height + 20)
        UIView.animate(withDuration: 0.15) {
            tabbar.frame = frame
            self.balloonString.frame = balloonFrame
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
    
    @IBAction func scrollToTop(_ sender: Any) {
        setWantsScrollToTop()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? ProductDetailViewController {
            vc.productQuery = (sender as! CollectionProductItem).id
        }
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hotItems.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseID.cell, for: indexPath) as! PhotoGalleryPageCell
        cell.updateViews(with: hotItems[indexPath.row].cover)
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
        vc.showDetailAction = {[weak self] item in
            self?.showDetail(for: item)
        }
        headerController = vc
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showDetail(for: hotItems[indexPath.row])
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let isLast = indexPath.row == (hotItems.count - 1)
        if isLast {
            hotList.loadMoreIfAllowed()
        }
    }
}

private extension HotCollectionViewController {
    func showDetail(for item: CollectionItemPreviewing) {
        if let product = item as? CollectionProductItem {
            performSegue(withIdentifier: SegueID.showProductDetail, sender: product)
        } else if let category = item as? CollectionCategoryItem {
            router.handle(DeepLinks.categoryList.appendingPathComponent(category.id))
        } else if let ad = item as? PromotionAd {
            if let link = ad.link {
                router.handle(link)
            }
        }
    }
    
    func prepareLists() {
        let hot = HotItemList(session: userSession)
        let banner = BannerItemList(session: userSession)
        var handles: [Any] = []
        handles.append(hot.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleHotListUpdate()
            }
        })
        handles.append(hot.addFetchingFailureHandler({[weak self] (error) in
            OperationQueue.main.addOperation {
                self?.handleHotListUpdateFailure(with: error)
            }
        }))
        handles.append(banner.addItemDidFetchHandler {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleBannerUpdate()
            }
        })
        updateHandles = handles
        hotList = hot
        bannerList = banner
        hot.reload()
        banner.reload()
    }
    
    func handleHotListUpdate() {
        refreshControl.endRefreshing()
        hotItems = hotList.items.compactMap{ $0.previewable }
        collectionView.reloadData()
        updateBackground()
    }
    
    func handleHotListUpdateFailure(with error: Error?) {
        refreshControl.endRefreshing()
        updateBackground(with: error)
    }
    
    func handleBannerUpdate() {
        headerController?.items = bannerList.items.compactMap{$0.previewable}
        updateBackground()
    }
    
    func updateBackground(with error: Error? = nil) {
        let shouldShowBackground = bannerList.items.isEmpty && hotItems.isEmpty
        if shouldShowBackground {
            let view = SimpleEmptyView.fromDefaultNib()
            view.titleLabel.text = Localized.emptyMessages.generic
            view.detailLabel.text = error?.localizedDescription
            collectionView.backgroundView = view
        } else {
            collectionView.backgroundView = nil
        }
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if hotList.items.isEmpty {
            return .zero
        }
        let w = collectionView.bounds.width
        return CGSize(width: w, height: (w / 9) * 4)
    }
}

extension HotCollectionViewController: ScrollToTopHandler {
    func setWantsScrollToTop() {
        collectionView.setContentOffset(.zero, animated: true)
    }
}

extension HotCollectionViewController {
    struct ReuseID {
        static let cell = "cell"
        static let header = "header"
    }
    struct SegueID {
        static let showPromoPopup = "showPromoPopup"
        static let showProductDetail = "showProductDetail"
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
