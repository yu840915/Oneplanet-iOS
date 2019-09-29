//
//  UserFlowMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UserFlowMainViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    static var ballonPadding: CGFloat = 0
    var userSession: UserSession!
    private var contentTabbarController: UITabBarController!
    private var auctionController: AuctionMainViewController!
    private var postController: PostFeedMainViewController!
    private var profileController: MyProfileViewController!
    private var hotPageController: HotCollectionViewController!
    private var noticeController: NoticeTableViewController!
    private var treasuryBarController: TreasuryBarViewController!
    fileprivate var getPageListOperaion: GetPromotionPageListOperation?
    fileprivate var appearanceAction: (()->())?
    fileprivate var hasViewBeenVisible = false
    private var appActivityHandles: [Any]?
    private var userActionRounter: URLRouter!
    @IBOutlet weak var balloonString: UIImageView!
    @IBOutlet weak var balloonRightPadding: NSLayoutConstraint!
    @IBOutlet weak var balloonButton: UIButton!
    var balloonNavigationCoordinator: BalloonNavigationCoordinator?
    var statusBarHandle: Any?
    var unreadCountHandle: Any!
    var currentSessionEndTime: Date?
    private var postQuota: ValuedPostQuota?
    private var noticesUnreadCount: NoticeUnreadCount!
    
    class func fromDefaultStoryboard() -> UserFlowMainViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateInitialViewController() as! UserFlowMainViewController
    }
    
    deinit {
        router.removeOverridingRouter(userActionRounter)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        noticesUnreadCount = NoticeUnreadCount(userSession: userSession)
        unreadCountHandle = noticesUnreadCount.updateHandlers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateViewsForUnreadCount()
            }
        }
        let contents = contentTabbarController.viewControllers!.compactMap{$0 as? UINavigationController}.compactMap{$0.viewControllers.first}
        contents.forEach {
            if let vc = $0 as? AuctionMainViewController {
                auctionController = vc
            } else if let vc = $0 as? PostFeedMainViewController {
                postController = vc
            } else if let vc = $0 as? MyProfileViewController {
                profileController = vc
            } else if let vc = $0 as? NoticeTableViewController {
                vc.unreadCount = noticesUnreadCount
                noticeController = vc
            }
        }
        setUpTabbarBackground()
        getPromoPopupIfNeeded()
        prepareRouter()
        [balloonButton, balloonString].forEach{
            $0?.layer.shadowColor = UIColor.black.cgColor
            $0?.layer.shadowOpacity = 1.0
            $0?.layer.shadowRadius = 4
            $0?.layer.shadowOffset = .init(width: -2, height: 4)
        }
        if !userSession.isAdmin && !userSession.isGuest {
            let q = ValuedPostQuota(userSession: userSession)
            postQuota = q
            q.refresh()
            noticesUnreadCount.refresh()
        }
        prepareAppActivityHandlers()
        updateViewsForUnreadCount()
    }
    
    func updateViewsForUnreadCount() {
        if let count = noticesUnreadCount.count, count > 0 {
            noticeController.navigationController?.tabBarItem.badgeValue = SharedNumberFormatters.integer.string(for: count)
        } else {
            noticeController.navigationController?.tabBarItem.badgeValue = nil
        }
    }
    
    private func prepareAppActivityHandlers() {
        var handles = [Any]()
        handles.append(AppLifeCycleObserver.didBecomeActive.observers.add {[weak self] (_) in
            OperationQueue.main.addOperation {
                self?.refreshDataOnWaking()
            }
        })
        handles.append(AppLifeCycleObserver.didEnterBackground.observers.add({[weak self] (_) in
            self?.recordBidSessionEndTime()
        }))
        appActivityHandles = handles
    }
    
    private func refreshDataOnWaking() {
        if !userSession.isGuest && !userSession.isAdmin {
            noticesUnreadCount.refresh()
        }
        refreshIfSessionEndedOnWaking()
        getPromoPopupIfNeeded()
    }
    
    private func recordBidSessionEndTime() {
        currentSessionEndTime = userSession.bidPhaseIndicator.sessionEndDate
    }
    
    private func refreshIfSessionEndedOnWaking() {
        guard let date = currentSessionEndTime,
            date.timeIntervalSinceNow < 0 else {
            currentSessionEndTime = nil
            return
        }
        currentSessionEndTime = nil
        userSession.lotList.reload()
        hotPageController.setNeedsRefresh()
        auctionController.setNeedsRefresh()
        userSession.bidPhaseIndicator.refreshIfNeeded()
    }
    
    private func setUpTabbarBackground() {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "im_tabbar_nor"))
        var frame = imageView.frame
        frame.size.width = UIScreen.main.bounds.width
        frame.origin.y = 20
        imageView.frame = frame
        contentTabbarController.tabBar.addSubview(imageView)
        contentTabbarController.tabBar.sendSubviewToBack(imageView)
        let hot = contentTabbarController.viewControllers?.compactMap{$0 as? UINavigationController}.compactMap{$0.viewControllers.first as? HotCollectionViewController}.first
        hotPageController = hot
        hot?.balloonString = balloonString
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let tabItem = contentTabbarController.tabBar.subviews.last,
            tabItem.frame.origin.x > 0 else {
            return
        }
        let rect = tabItem.convert(tabItem.bounds, to: view)
        let offset = (rect.width - 64) / 2
        let padding = view.bounds.maxX - rect.maxX + offset
        let expPadding = -(padding + 10)
        if balloonRightPadding.constant != expPadding {
            balloonRightPadding.constant = expPadding
            UserFlowMainViewController.ballonPadding = expPadding
            view.setNeedsLayout()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasViewBeenVisible = true
        appearanceAction?()
        appearanceAction = nil
        router.resume()
        if balloonNavigationCoordinator == nil {
            handleTabbarSwitch()
        }
        statusBarHandle = StatusBarFrameObserver.shared.statusBarHeightChangeObserverse.add {[weak self] in
            self?.handleStatusBarChange()
        }
    }
    
    private func handleStatusBarChange() {
        if TabFeature.list[contentTabbarController.selectedIndex] == .hot {
            return
        }
        updateBalloonAppearance()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        statusBarHandle = nil
    }
    
    @IBAction func showCreationPortalIfAllowed(_ sender: UIButton) {
        showCreationPortalIfAllowed()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let tabbar = segue.destination as? UITabBarController {
            tabbar.delegate = self
            tabbar.viewControllers?
                .compactMap{$0 as? UINavigationController}
                .compactMap{
                    $0.viewControllers.first as? UserSessionDepending
                }
                .forEach{
                    $0.userSession = userSession
            }
            var titles = [
                Localized.feature.hot,
                Localized.feature.life,
                Localized.feature.bid,
                Localized.feature.notice,
                Localized.feature.me
            ]
            tabbar.viewControllers?.forEach{
                $0.tabBarItem.title = titles.removeFirst()
                if let nav = $0 as? UINavigationController {
                    NavigationBarStyle.darkGray.configure(nav.navigationBar)
                }
                $0.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
            }
            tabbar.tabBar.backgroundImage = UIImage()
            contentTabbarController = tabbar
        } else if let vc = segue.destination as? TreasuryBarViewController {
            vc.userSession = userSession
            treasuryBarController = vc
        } else if let vc = segue.destination as? PostCreationPortalViewController {
            vc.startPostCreationFlow = {[weak self] draft in
                self?.dismiss(animated: true, completion: {
                    self?.showPostComposer(with: draft)
                })
            }
            vc.quota = postQuota
        } else if let nav = segue.destination as? UINavigationController {
            if let vc = nav.viewControllers.first as? PostCreationFlowViewController {
                vc.userSession = userSession
                vc.postDraft = (sender as! PostDraft)
                vc.didPublish = {[weak self] _ in
                    self?.handleNewPost()
                }
            } else if let vc = nav.viewControllers.first as? WebViewController {
                NavigationBarStyle.darkGray.configure(nav.navigationBar)
                vc.exitTitle = Localized.titles.done
                vc.request = URLRequest(url: sender as! URL)
            }
        } else if let container = segue.destination as? PopUpContainerViewController {
            container.contentViewControllerSetUpBlock = {vc in
                if let popup = vc as? GemActionPopUpViewController {
                    popup.configuration = (sender as! GemActionPopUpConfiguration)
                    popup.cancelAction = {[weak self] in
                        self?.dismiss(animated: true, completion: nil)
                    }
                    popup.mainAction = {[weak self] in
                        self?.dismiss(animated: true, completion: {
                            router.handle(DeepLinks.postEditor)
                        })
                    }
                }
            }
        }
    }
}

fileprivate extension UserFlowMainViewController {
    func handleNewPost() {
        switchToTab(.life)
        userSession.wallet.setNeedsUpdateBlueGem()
        postQuota?.refresh()
        handlePostUpdate()
    }
    
    func handlePostUpdate() {
        postController.setNeedsRefresh()
        profileController.setNeedsRefresh()
    }
    
    func showCreationPortalIfAllowed() {
        if userSession.isBanned {
            switchToTab(.my)
            return
        }
        let op = FeatureAccessCheckOperation(userSession: userSession)
        op.start()
        if op.isAccessible {
            performSegue(withIdentifier: SegueID.showPostCreationPortal, sender: nil)
        }
    }
    
    func showPostComposer(with draft: PostDraft) {
        performSegue(withIdentifier: SegueID.showPostComposer, sender: draft)
    }
    
    func prepareRouter() {
        let actionRouter = URLRouter()
        actionRouter.add(DeepLinks.lifeTab.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.switchToTab(.life)
            }
            return true
        }
        actionRouter.add(DeepLinks.noticeTab.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.switchToTab(.notice)
            }
            return true
        }
        actionRouter.add(DeepLinks.meTab.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.switchToTab(.my)
            }
            return true
        }
        actionRouter.add(DeepLinks.postEditor.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.showCreationPortalIfAllowed()
            }
            return true
        }
        actionRouter.add(DeepLinks.categoryListPattern.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.showCategoryList(with: info["query"] as! String)
            }
            return true
        }
        actionRouter.add(DeepLinks.insufficientFundPopUp.path) {[weak self] (_) -> Bool in
            OperationQueue.main.addOperation {
                self?.showInsufficientFundPopUp()
            }
            return true
        }
        actionRouter.add("*") {[weak self] (info) -> Bool in
            return self?.routeToWebViewIfNeeded(with: info) ?? false
        }
        self.userActionRounter = actionRouter
        router.addOverridingRouter(actionRouter)
    }
    
    func switchToTab(_ tab: TabFeature) {
        guard checkAccess(forTab: tab),
            let idx = TabFeature.list.index(of: tab) else {
                return
        }
        contentTabbarController.selectedViewController = contentTabbarController.viewControllers![idx]
        OperationQueue.main.addOperation {
            self.handleTabbarSwitch()
        }
    }

    func checkAccess(forTab tab: TabFeature) -> Bool {
        if tab == .life && userSession.isBanned {
            OperationQueue.main.addOperation {
                self.switchToTab(.my)
            }
            return false
        }
        switch tab {
        case .hot, .bid:
            return true
        case .life, .notice, .my:
            let op = FeatureAccessCheckOperation(userSession: userSession)
            op.start()
            return op.isAccessible
        }
    }
    
    func updateBalloonAppearance() {
        let showingBid = TabFeature.list[contentTabbarController.selectedIndex] == .bid
        let canShowWithNav = balloonNavigationCoordinator?.canShowBalloon ?? true
        if canShowWithNav {
            OperationQueue.main.addOperation {
                self.adjustTabBarFrame()
            }
        }
        [balloonButton, balloonString].forEach{$0?.isHidden = showingBid || !canShowWithNav}
    }
    
    func adjustTabBarFrame() {
        let hot = contentTabbarController.viewControllers!.compactMap{$0 as? UINavigationController}.compactMap{$0.viewControllers.first as? HotCollectionViewController}.first!
        contentTabbarController.tabBar.frame = hot.expectedTabbarFrame.applying(hot.balloonTransform)
        balloonString.frame = hot.expectedBalloonStringFrame.applying(hot.balloonTransform)
    }
    
    func showCategoryList(with query: String) {
        switchToTab(.bid)
        auctionController.showCategoryList(with: query)
    }
    
    func showInsufficientFundPopUp() {
        performSegue(withIdentifier: SegueID.showInsufficienFundPopUp, sender: InsufficientBlueGemPopUpConfiguration())
    }
    
    func routeToWebViewIfNeeded(with info: [String: Any]) -> Bool {
        guard let url = info[URLRouter.Keys.url] as? URL else {
            return false
        }
        let isHTTP = url.scheme?.lowercased().hasPrefix("http") == true
        let isNotAPI = url.host?.lowercased() != ServiceURLs.base.host?.lowercased()
        guard isHTTP && isNotAPI else {return false}
        OperationQueue.main.addOperation {
            self.performSegue(withIdentifier: SegueID.showWebView, sender: url)
        }
        return true
    }
}

extension UserFlowMainViewController {
    struct SegueID {
        static let showPostCreationPortal = "showPostCreationPortal"
        static let showPostComposer = "showPostComposer"
        static let showWebView = "showWebView"
        static let showInsufficienFundPopUp = "showInsufficienFundPopUp"
    }
}

fileprivate extension UserFlowMainViewController {
    func getPromoPopupIfNeeded() {
        guard !userSession.isGuest else { return }
        if userSession.bidPhaseIndicator.biddingHasStarted && userSession.bidPhaseIndicator.phase != .ended {
            return
        }
        if let lastDate = Preferences.lastPromoPopUpShowUpDate.value,
            Date().timeIntervalSince(lastDate) < appConfiguration.promoPopUpCoolDownInterval {
            return
        }
        guard promoPopUpSupressionRequests.isEmpty else { return }
        guard getPageListOperaion == nil else { return }
        let op = GetPromotionPageListOperation(session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetPromoPopup()
            }
        }
        getPageListOperaion = op
        op.start()
    }
    
    func didGetPromoPopup() {
        let op = getPageListOperaion!
        getPageListOperaion = nil
        guard let list = op.list, !list.pages.isEmpty else { return }
        Preferences.lastPromoPopUpShowUpDate.value = Date()
        showPromoPagesIfVisible(with: list)
    }
    
    func showPromoPagesIfVisible(with list: PromotionPageList) {
        guard hasViewBeenVisible else {
            appearanceAction = {[weak self] in
                self?.showPromoPagesIfVisible(with: list)
            }
            return
        }
        let vc = PromoPopUpFlowViewController.fromDefaultStoryboard()
        vc.promoPageList = list
        vc.userSession = userSession
        FrontViewControllerFinder.findFront()?.present(vc, animated: true, completion: nil)
    }
}

extension UserFlowMainViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard let idx = tabBarController.viewControllers?.index(of: viewController) else { return false }
        setScrollToTopIfNeeded(tabBarController, viewController: viewController)
        return checkAccess(forTab: TabFeature.list[idx])
    }
    
    private func setScrollToTopIfNeeded(_ tabBarController: UITabBarController, viewController: UIViewController) {
        guard tabBarController.selectedViewController == viewController else {
            return
        }
        if let nav = viewController as? UINavigationController,
            let handler = nav.topViewController as? ScrollToTopHandler {
            handler.setWantsScrollToTop()
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        handleTabbarSwitch()
    }
    
    func handleTabbarSwitch() {
        let nav = contentTabbarController.viewControllers![contentTabbarController.selectedIndex] as! UINavigationController
        let coord = BalloonNavigationCoordinator(navigationController: nav)
        coord.balloonAppearanceHandler = {[weak self] in
            self?.updateBalloonAppearance()
        }
        if let vc = nav.viewControllers.first as? AuctionMainViewController {
            vc.setWantsTutorial()
        }
        balloonNavigationCoordinator = coord
        updateBalloonAppearance()
    }
    
}

enum TabFeature {
    case hot, life, my, notice, bid
    static let list: [TabFeature] = [.hot, .life, .bid, .notice, .my]
}

extension UIViewController {
    var isXgenerationScreen: Bool {
        return UIApplication.shared.keyWindow!.isXgenerationScreen
    }
}

extension UIWindow {
    var isXgenerationScreen: Bool {
        return max(safeAreaInsets.bottom, safeAreaInsets.left, safeAreaInsets.right) > 0
    }
}

class FrontViewControllerFinder: NSObject {
    class func findFront() -> UIViewController? {
        return findRoot()?.frontPresentedController
    }
    
    class func findRoot() -> UIViewController? {
        return (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController
    }
}

extension UIViewController {
    var frontPresentedController: UIViewController {
        return presentedViewController?.frontPresentedController ?? self
    }
}

protocol ScrollToTopHandler: AnyObject {
    func setWantsScrollToTop()
}

class BalloonNavigationCoordinator: NSObject, UINavigationControllerDelegate {
    var balloonAppearanceHandler: (()->())?
    private(set) var canShowBalloon: Bool {
        didSet {
            if oldValue != canShowBalloon {
                balloonAppearanceHandler?()
            }
        }
    }
    let navigationController: UINavigationController
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        canShowBalloon = (navigationController.viewControllers.count == 1)
        super.init()
        navigationController.delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController != navigationController.viewControllers.first {
            canShowBalloon = false
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController == navigationController.viewControllers.first {
            canShowBalloon = true
        }
    }
}
