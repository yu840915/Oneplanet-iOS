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
    private weak var userFlowRootController: UserFlowRootViewController?
    private var shouldAddConstraintsForUserFlow = false
    private var sessionEndHandle: Any?
    private var activeHandle: Any!
    private var updateInfo: UpdateInfo?
    private weak var alert: UIAlertController?
    private var versionCheck: VersionCheckOperation?
    private var lastVersionCheckDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activeHandle = AppLifeCycleObserver.didBecomeActive.observers.add{[weak self] _ in
            OperationQueue.main.addOperation {
                self?.checkVersionOnWakingIfNeeded()
            }
        }
        let op = VersionCheckOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleInitialCheck()
            }
        }
        versionCheck = op
        op.start()
    }
    
    func handleInitialCheck() {
        let op = versionCheck!
        if let info = op.updateInfo, info.forced {
            updateInfo = info
            showUpdateAlert(with: info)
        } else {
            restoreUserSession()
        }
    }
    
    func checkVersionOnWakingIfNeeded() {
        guard alert == nil else { return }
        if let info = updateInfo, info.forced {
            showUpdateAlert(with: info)
        } else {
            checkVersionIfNeeded()
        }
    }
    
    private func checkVersionIfNeeded() {
        if lastVersionCheckDate.timeIntervalSinceNow.magnitude > 6 * .hour {
            checkVersion()
        }
    }
    
    private func checkVersion() {
        guard versionCheck == nil else { return }
        let op = VersionCheckOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didCheckVersion()
            }
        }
        versionCheck = op
        op.start()
    }
    
    private func didCheckVersion() {
        let op = versionCheck!
        versionCheck = nil
        if op.success == true {
            lastVersionCheckDate = Date()
        }
        if let info = op.updateInfo {
            updateInfo = info
            showUpdateAlert(with: info)
        }
    }
    
    private func showUpdateAlert(with info: UpdateInfo) {
        let alert = UIAlertController(title: "New Version", message: info.version, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Upgrade", style: .default, handler: { (_) in
            UIApplication.shared.open(info.url, options: [:], completionHandler: nil)
        }))
        if !info.forced {
            alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        }
        let presenter = FrontViewControllerFinder.findFront() ?? frontPresentedController
        presenter.present(alert, animated: true, completion: nil)
        self.alert = alert
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        IAPTransactionProcessor.shared.userSession = nil
    }
    
    private func startUserFlow(with session: UserSession, needsPreflightCheck: Bool) {
        guard userFlowRootController == nil else {
            assertionFailure("User flow already exists")
            return
        }
        IAPTransactionProcessor.shared.userSession = session
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
        vc.dismiss(animated: false, completion: nil)
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

class VersionCheckOperation: AlamofireAPIAccessOperation {
    private(set) var updateInfo: UpdateInfo?
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: ServiceURLs.base.appendingPathComponent("preflight"))
    }
    
    override func handleClientError(with response: HTTPURLResponse) throws {
        if response.statusCode == 426 {
            return
        }
    }
    
    override func processData(with data: Data) throws {
        updateInfo = try JSONDecoder.default.decode(UpdateInfo.self, from: data)
    }
}

class UpdateInfo: Decodable {
    let forced: Bool
    let url: URL
    let version: String
}
