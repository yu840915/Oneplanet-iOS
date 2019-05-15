//
//  UserFlowRootViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol UserSessionDepending: AnyObject {
    var userSession: UserSession! {set get}
}

class UserFlowRootViewController: UIViewController, UserSessionDepending {
    class var defaultStoryboardID: String {
        return "UserSessionRootViewController"
    }
    
    var userSession: UserSession!
    var needsPreflightCheck = true
    private var mainViewController: UserFlowMainViewController?
    private var shouldAddConstraintsForMainView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !needsPreflightCheck {
            startMainFlow()
        }
    }
    
    private func startMainFlow() {
        guard mainViewController == nil else { return }
        let vc = UserFlowMainViewController.fromDefaultStoryboard()
        vc.userSession = userSession
        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
        mainViewController = vc
        shouldAddConstraintsForMainView = true
        updateViewConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if needsPreflightCheck {
            performSegue(withIdentifier: SegueID.preflightCheck, sender: nil)
        }
    }
    
    override func updateViewConstraints() {
        if shouldAddConstraintsForMainView,
            let content = mainViewController?.view {
            shouldAddConstraintsForMainView = false
            let views = ["content":  content]
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
        }
        super.updateViewConstraints()
    }
    
    private func leavePreflightCheck() {
        dismiss(animated: true, completion: nil)
        startMainFlow()
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
