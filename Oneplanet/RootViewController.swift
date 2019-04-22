//
//  RootViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    private var restoreUserSessionOperation: RestoreUserSessionOperation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        restoreUserSession()
    }
    
    private func restoreUserSession() {
        guard restoreUserSessionOperation == nil else {
            return
        }
        let op = RestoreUserSessionOperation()
        restoreUserSessionOperation = op
        op.completionBlock = {[weak self] in
            self?.handleSessionRestoration()
        }
        OperationQueue.main.addOperation(op)
    }
    
    private func handleSessionRestoration() {
        let op = restoreUserSessionOperation!
        if let session = op.session {
            startUserFlow(with: session)
        } else {
            startLoginFlow()
        }
    }
    
    private func startUserFlow(with session: UserSession) {
        
    }
    
    private func startLoginFlow() {
        if UserProgressChecklist.watchWelcomeMessage.isFinished {
            performSegue(withIdentifier: SegueID.showLogin, sender: nil)
        } else {
            performSegue(withIdentifier: SegueID.showWelcomePage, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

extension RootViewController {
    struct SegueID {
        static let showLogin = "showLogin"
        static let showWelcomePage = "showWelcomePage"
    }
}
