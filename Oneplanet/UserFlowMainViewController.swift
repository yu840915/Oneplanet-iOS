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
            contentTabbarController = tabbar
        }
    }

}
