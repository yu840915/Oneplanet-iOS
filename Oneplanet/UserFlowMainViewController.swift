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
    fileprivate var getPageListOperaion: GetPromotionPageListOperation?
    fileprivate var appearanceAction: (()->())?
    fileprivate var hasViewBeenVisible = false
    private var appBecomeActiveHandle: Any?


    class func fromDefaultStoryboard() -> UserFlowMainViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateInitialViewController() as! UserFlowMainViewController
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
    }
    
    private func setUpTabbarBackground() {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "im_tabbar_nor"))
        var frame = imageView.frame
        frame.size.width = UIScreen.main.bounds.width
        frame.origin.y = 20
        imageView.frame = frame
        contentTabbarController.tabBar.addSubview(imageView)
        contentTabbarController.tabBar.sendSubviewToBack(imageView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasViewBeenVisible = true
        appearanceAction?()
        appearanceAction = nil
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabbar = segue.destination as? UITabBarController {
            tabbar.viewControllers?
                .compactMap{$0 as? UINavigationController}
                .compactMap{
                    $0.viewControllers.first as? UserSessionDepending
                }
                .forEach{
                    $0.userSession = userSession
            }
            tabbar.viewControllers?.forEach{
                if let nav = $0 as? UINavigationController {
                    NavigationBarStyle.darkGray.configure(nav.navigationBar)
                }
                $0.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
            }
            tabbar.tabBar.backgroundImage = UIImage()
            contentTabbarController = tabbar
        }
    }

}

fileprivate extension UserFlowMainViewController {
    func getPromoPopupIfNeeded() {
//        if let lastDate = Preferences.lastPromoPopUpShowUpDate.value,
//            Date().timeIntervalSince(lastDate) < appConfiguration.promoPopUpCoolDownInterval {
//            return
//        }
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
//        Preferences.lastPromoPopUpShowUpDate.value = Date()
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
        present(vc, animated: true, completion: nil)
    }
}

extension UIViewController {
    var isXgenerationScreen: Bool {
        let insets = UIApplication.shared.keyWindow!.safeAreaInsets
        let inset = max(insets.bottom, insets.left, insets.right)
        return inset > 0
    }
}
