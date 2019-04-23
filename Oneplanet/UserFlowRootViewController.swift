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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
