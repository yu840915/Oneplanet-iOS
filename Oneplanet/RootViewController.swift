//
//  RootViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol DefaultInstanceFactory: AnyObject {
    associatedtype ViewControllerType where ViewControllerType: UIViewController
    static func fromDefaultStoryboard() -> ViewControllerType
}

protocol DefaultViewInstanceFactory: AnyObject {
    associatedtype ViewType where ViewType: UIView
    static func fromDefaultNib() -> ViewType
}

class RootViewController: UIViewController {
    private var restoreUserSessionOperation: RestoreUserSessionOperation?
    @IBOutlet weak var containerView: UIView!
    private var userFlowRootController: UserFlowRootViewController?
    private var shouldAddConstraintsForUserFlow = false
    private var sessionEndHandle: Any?
    
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
            OperationQueue.main.addOperation {
                self?.handleSessionRestoration()
            }
        }
        OperationQueue.main.addOperation(op)
    }
    
    private func handleSessionRestoration() {
//        startUserFlow(with: UserSession(token: "123"), needsPreflightCheck: false)
        let op = restoreUserSessionOperation!
        if let session = op.session {
            startUserFlow(with: session, needsPreflightCheck: true)
        } else {
            startLoginFlow()
        }
    }
    
    private func logOut() {
        endUserFlow()
        LogOutOperation().start()
        startLoginFlow()
    }
    
    private func startUserFlow(with session: UserSession, needsPreflightCheck: Bool) {
        guard userFlowRootController == nil else {
            assertionFailure("User flow already exists")
            return
        }
        let vc = storyboard!.instantiateViewController(withIdentifier: UserFlowRootViewController.defaultStoryboardID) as! UserFlowRootViewController
        vc.userSession = session
        vc.needsPreflightCheck = needsPreflightCheck
        sessionEndHandle = session.sessionBecomeInactiveObservers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.logOut()
            }
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        vc.didMove(toParent: self)
        userFlowRootController = vc
        shouldAddConstraintsForUserFlow = true
        updateViewConstraints()
    }
    
    private func endUserFlow() {
        guard let vc = userFlowRootController else {
            assertionFailure("User flow doesn't exist")
            return
        }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
    }
    
    private func dismissLoginFlowAndStarUserFlow(with session: UserSession) {
        dismiss(animated: true, completion: nil)
        startUserFlow(with: session, needsPreflightCheck: false)
    }
    
    private func startLoginFlow() {
        if UserProgressChecklist.watchWelcomeMessage.isFinished {
            performSegue(withIdentifier: SegueID.showLogin, sender: nil)
        } else {
            performSegue(withIdentifier: SegueID.showWelcomePage, sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController, let authFlow = nav.viewControllers.first as? AuthorizationFlowEntryPoint {
            authFlow.authorizationCompletion = {[weak self] session in
                OperationQueue.main.addOperation {
                    self?.dismissLoginFlowAndStarUserFlow(with: session)
                }
            }
        }
    }
    
    override func updateViewConstraints() {
        if shouldAddConstraintsForUserFlow,
            let content = userFlowRootController?.view {
            shouldAddConstraintsForUserFlow = false
            content.translatesAutoresizingMaskIntoConstraints = false
            let views = ["content": content]
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
        }
        super.updateViewConstraints()
    }
}

extension RootViewController {
    struct SegueID {
        static let showLogin = "showLogin"
        static let showWelcomePage = "showWelcomePage"
    }
}
