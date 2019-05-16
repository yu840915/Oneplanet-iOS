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
    
    class func fromDefaultStoryboard() -> UserFlowMainViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateInitialViewController() as! UserFlowMainViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTabbarBackground()
    }
    
    private func setUpTabbarBackground() {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "im_tabbar_nor"))
        var frame = imageView.frame
        frame.size.width = UIScreen.main.bounds.width
        imageView.frame = frame
        contentTabbarController.tabBar.addSubview(imageView)
        contentTabbarController.tabBar.sendSubviewToBack(imageView)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tabbar = segue.destination as? UITabBarController {
            tabbar.viewControllers?
                .compactMap{$0 as? UINavigationController}
                .compactMap{$0.viewControllers.first as? UserSessionDepending}
                .forEach{
                    $0.userSession = userSession
            }
            tabbar.tabBar.backgroundImage = UIImage()
            debugPrint(tabbar.tabBar.subviews)
            contentTabbarController = tabbar
        }
    }

}

extension UIViewController {
    var isXgenerationScreen: Bool {
        let insets = UIApplication.shared.keyWindow!.safeAreaInsets
        let inset = max(insets.bottom, insets.left, insets.right)
        return inset > 0
    }
}
