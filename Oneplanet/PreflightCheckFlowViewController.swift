//
//  PreflightCheckFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PreflightCheckFlowViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var didFinishPreflightCheck: (()->())?
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var errorView: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    private var contentViewController: UIViewController?
    private var shouldAddConstraintsForContent = false
    
    private var getProfileOperation: GetMyProfileOperation? {
        didSet {
            updateViewsForRunningOperations()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retryButton.setTitle(Localized.phrases.tryAgain, for: .normal)
        startPreflightCheck()
    }
    
    private func updateViewsForRunningOperations() {
        let isRunning = getProfileOperation != nil
        loadingIndicator.isHidden = !isRunning
        if isRunning {
            errorView.isHidden = true
        }
    }
    
    private func startPreflightCheck() {
        getMyProfile()
    }
    
    private func getMyProfile() {
        let op = GetMyProfileOperation(session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetMyProfile()
            }
        }
        getProfileOperation = op
        op.start()
    }
    
    private func didGetMyProfile() {
        let op = getProfileOperation!
        getProfileOperation = nil
        if op.profile != nil {
            didFinishPreflightCheck?()
        } else if op.missingProfile == true {
            startProfileCreation()
        } else {
            notifyFailure(with: op.error)
        }
    }
    
    private func startProfileCreation() {
        let nav = storyboard!.instantiateViewController(withIdentifier: "createProfileEntryPoint") as! UINavigationController
        let vc = nav.viewControllers.first as! CreateProfileViewController
        vc.userSession = userSession
        vc.didCreateProfile = {[weak self] in
            self?.didFinishPreflightCheck?()
        }
        addChild(vc)
        containerView.addSubview(vc.view)
        NavigationBarStyle.translucent.configure(nav.navigationBar)
        vc.didMove(toParent: self)
        contentViewController = vc
        shouldAddConstraintsForContent = true
        updateViewConstraints()
    }
    
    private func notifyFailure(with error: Error?) {
        errorView.isHidden = false
        errorLabel.text = error?.localizedDescription
    }
    
    @IBAction func retry(_ sender: UIButton) {
        startPreflightCheck()
    }
    
    override func updateViewConstraints() {
        if shouldAddConstraintsForContent,
            let content = contentViewController?.view {
            shouldAddConstraintsForContent = false
            content.translatesAutoresizingMaskIntoConstraints = false
            let views = ["content": content]
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[content]|", options: [], metrics: nil, views: views))
            containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[content]|", options: [], metrics: nil, views: views))
        }
        super.updateViewConstraints()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}
