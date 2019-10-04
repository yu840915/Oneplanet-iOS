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
    private var getBidSessionTimeframeOperation: GetBidSessionTimeframeOperation? {
        didSet {
            updateViewsForRunningOperations()
        }
    }
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !userSession.isActive {
            dismiss(animated: false, completion: nil)
        }
    }
    
    private func updateViewsForRunningOperations() {
        let isRunning = getProfileOperation != nil || getBidSessionTimeframeOperation != nil
        loadingIndicator.isHidden = !isRunning
        if isRunning {
            errorView.isHidden = true
        }
    }
    
    private func getBidSessionTimeframe() {
        let op = GetBidSessionTimeframeOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetTimeframe()
            }
        }
        getBidSessionTimeframeOperation = op
        op.start()
    }
    
    private func didGetTimeframe() {
        let op = getBidSessionTimeframeOperation!
        getBidSessionTimeframeOperation = nil
        if let timeframe = op.timeframe {
            userSession.updateBidPhaseIndicator(with: timeframe)
            startPreflightCheck()
        } else {
            notifyFailure(with: op.error)
        }
    }
    
    private func startPreflightCheck() {
        if userSession.bidPhaseIndicator == nil {
            getBidSessionTimeframe()
        } else {
            startProfileCheck()
        }
    }
    
    private func startProfileCheck() {
        if userSession.isGuest {
            didFinishPreflightCheck?()
            return
        }
        if let profile = userSession.profile {
            nextStep(with: profile)
        } else {
            getMyProfile()
        }
    }
    
    private func nextStep(with profile: MyProfile) {
        if profile.nickname.isEmpty {
            startProfileCreation(with: profile)
        } else if profile.alien == nil {
            startSelectCharacter(with: profile)
        } else {
            didFinishPreflightCheck?()
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
            nextStep(with: profile)
        } else {
            notifyFailure(with: op.error)
        }
    }
    
    private func startProfileCreation(with profile: MyProfile) {
        performSegue(withIdentifier: SegueID.createProfile, sender: profile)
    }
    
    private func startSelectCharacter(with profile: MyProfile) {
        performSegue(withIdentifier: SegueID.selectCharacter, sender: profile)
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
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? CreateProfileViewController {
            vc.profileDraft = ProfileDraft(profile: (sender as! MyProfile))
            vc.didCreateProfile = {[weak self] in
                self?.didFinishPreflightCheck?()
            }
        }
        if let vc = segue.destination as? CharacterPickerViewController {
            vc.draft = ProfileDraft(profile: (sender as! MyProfile))
            vc.didCreateProfile = {[weak self] in
                self?.didFinishPreflightCheck?()
            }
        }
        segue.destination.navigationItem.hidesBackButton = true
    }
}

extension PreflightCheckFlowViewController {
    struct SegueID {
        static let createProfile = "createProfile"
        static let selectCharacter = "selectCharacter"
    }
}
