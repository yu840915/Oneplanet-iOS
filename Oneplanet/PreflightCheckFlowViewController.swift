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
    
    private var getProfileOperation: GetMyProfileOperation? {
        didSet {
            updateViewsForRunningOperations()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        retryButton.setTitle(Localized.phrases.tryAgain, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        if userSession.isGuest {
            didFinishPreflightCheck?()
            return
        }
        if let profile = userSession.profile {
            if profile.nickname.isEmpty {
                startProfileCreation()
            } else {
                didFinishPreflightCheck?()
            }
        } else {
            getMyProfile()
        }
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
        if let profile = op.profile {
            userSession.updateProfile(profile)
            if profile.nickname.isEmpty {
                startProfileCreation()
            } else {
                didFinishPreflightCheck?()
            }
        } else {
            notifyFailure(with: op.error)
        }
    }
    
    private func startProfileCreation() {
        performSegue(withIdentifier: SegueID.createProfile, sender: userSession)
    }
    
    private func notifyFailure(with error: Error?) {
        errorView.isHidden = false
        errorLabel.text = error?.localizedDescription
    }
    
    @IBAction func retry(_ sender: UIButton) {
        startPreflightCheck()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CreateProfileViewController {
            vc.userSession = userSession
            vc.didCreateProfile = {[weak self] in
                self?.didFinishPreflightCheck?()
            }

        }
    }
}

extension PreflightCheckFlowViewController {
    struct SegueID {
        static let createProfile = "createProfile"
    }
}
