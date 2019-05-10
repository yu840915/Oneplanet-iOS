//
//  UserFlowRootViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol UserSessionDepending {
    var userSession: UserSession! {set get}
}

class UserFlowRootViewController: UIViewController, UserSessionDepending {
    class var defaultStoryboardID: String {
        return "UserSessionRootViewController"
    }
    var userSession: UserSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    private func startNormalFlow() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController, let vc = nav.viewControllers.first as? PreflightCheckFlowViewController {
            vc.userSession = userSession
            vc.didFinishPreflightCheck = {[weak self] in
                self?.startNormalFlow()
            }
        }
    }

}
