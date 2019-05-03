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
    @IBOutlet weak var preflightCheckFlowView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    private func startNormalFlow() {
        preflightCheckFlowView.isHidden = true
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PreflightCheckFlowViewController {
            vc.userSession = userSession
            vc.didFinishPreflightCheck = {[weak self] in
                self?.startNormalFlow()
            }
        }
    }

}
