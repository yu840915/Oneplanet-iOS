//
//  UserFlowMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UserFlowMainViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    var userSession: UserSession!
    private var contentTabbarController: UITabBarController!
    private var treasuryBarController: TreasuryBarViewController!
    fileprivate var getPageListOperaion: GetPromotionPageListOperation?
    fileprivate var appearanceAction: (()->())?
    fileprivate var hasViewBeenVisible = false
    private var appBecomeActiveHandle: Any?
    private var userActionRounter: URLRouter!
    @IBOutlet weak var balloonString: UIImageView!
    @IBOutlet weak var balloonRightPadding: NSLayoutConstraint!
    @IBOutlet weak var balloonButton: UIButton!
    
    class func fromDefaultStoryboard() -> UserFlowMainViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateInitialViewController() as! UserFlowMainViewController
    }
    
    deinit {
        router.removeOverridingRouter(userActionRounter)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTabbarBackground()
        getPromoPopupIfNeeded()
        appBecomeActiveHandle = AppLifeCycleObserver.didBecomeActive.observers.add {[weak self] (_) in
            OperationQueue.main.addOperation {
                self?.getPromoPopupIfNeeded()
            }
        }
        prepareRouter()
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
            view.setNeedsLayout()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasViewBeenVisible = true
        appearanceAction?()
        appearanceAction = nil
        router.resume()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
        }
    }

}

fileprivate extension UserFlowMainViewController {
    func prepareRouter() {
        let actionRouter = URLRouter()
        actionRouter.add(DeepLinks.lifeTab.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                return self?.switchToTab(.life)
            }
            return true
        }
        actionRouter.add(DeepLinks.noticeTab.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                return self?.switchToTab(.notice)
            }
            return true
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
    }

    func checkAccess(forTab tab: TabFeature) -> Bool {
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
        [balloonButton, balloonString].forEach{$0?.isHidden = showingBid}
    }
}

fileprivate extension UserFlowMainViewController {
    func getPromoPopupIfNeeded() {
        guard !userSession.isGuest else { return }
        if let lastDate = Preferences.lastPromoPopUpShowUpDate.value,
            Date().timeIntervalSince(lastDate) < appConfiguration.promoPopUpCoolDownInterval {
            return
        }
        guard promoPopUpSupressionRequests.isEmpty else { return }
        guard getPageListOperaion == nil else { return }
        let op = GetPromotionPageListOperation()
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
        updateBalloonAppearance()
    }
}

enum TabFeature {
    case hot, life, my, notice, bid
    static let list: [TabFeature] = [.hot, .life, .bid, .notice, .my]
}

extension UIViewController {
    var isXgenerationScreen: Bool {
        let insets = UIApplication.shared.keyWindow!.safeAreaInsets
        let inset = max(insets.bottom, insets.left, insets.right)
        return inset > 0
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
