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
    var needsPreflightCheck = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !needsPreflightCheck {
            startUserFlow()
        }
    }
    
    private func startUserFlow() {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if needsPreflightCheck {
            performSegue(withIdentifier: SegueID.preflightCheck, sender: nil)
        }
    }
    
    private func leavePreflightCheck() {
        dismiss(animated: true, completion: nil)
        startUserFlow()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController, let vc = nav.viewControllers.first as? PreflightCheckFlowViewController {
            vc.userSession = userSession
            vc.didFinishPreflightCheck = {[weak self] in
                self?.leavePreflightCheck()
            }
        }
    }

}

extension UserFlowRootViewController {
    struct SegueID {
        static let preflightCheck = "preflightCheck"
    }
}
