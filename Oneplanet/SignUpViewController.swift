//
//  SignUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

protocol EmailAuthFlowStep: AnyObject {
    var emailAuthCredential: EmailAuthCredential! {set get}
    var authorizationCompletion: ((UserSession)->())! {set get}
}

class SignUpViewController: UIViewController, EmailAuthFlowStep {

    @IBOutlet weak var socialLoginLabel: UILabel!
    @IBOutlet var socialLoginButtons: [UIButton]!
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var authOperation: SocialAuthenticationOperationType? {
        didSet {
            updateViewsForRunningAuthOperation()
        }
    }
    private var getAccountStateOperation: GetAccountStateOperation?
    var emailAuthCredential: EmailAuthCredential!
    var authorizationCompletion: ((UserSession) -> ())!
    private var inputChangeHandle: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        localizeTitles()
        emailAuthCredential = EmailAuthCredential()
        inputChangeHandle = emailAuthCredential.inputDidChangeHandlers.add {[weak self] in
            self?.updateViewForInputChange()
        }
        updateViewForInputChange()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(false)
    }
    
    private func localizeTitles() {
        title = Localized.titles.signUp
        socialLoginLabel.text = Localized.phrases.socialLogin
        emailLoginLabel.text = Localized.phrases.emailSignUp
        emailFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.email, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        signUpButton.setTitle(Localized.titles.signUp, for: .normal)
    }
    
    private func updateViewForInputChange() {
        let allowsAction = authOperation == nil
        signUpButton.isEnabled = allowsAction && !emailAuthCredential.email.isEmpty
    }

    private func getAccountState() {
        guard getAccountStateOperation == nil else {
            return
        }
        let op = GetAccountStateOperation(email: emailAuthCredential.email)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetAccountState()
            }
        }
        getAccountStateOperation = op
        op.start()
    }
    
    private func didGetAccountState() {
        let op = getAccountStateOperation!
        getAccountStateOperation = nil
        if op.success == true {
            resetErrorDisplay()
            switch op.state {
            case .nonexist:
                performSegue(withIdentifier: SegueID.emailVerification, sender: emailAuthCredential)
            case .pending, .verified:
                showInputError(with: Localized.errors.conflictingAccount)
            case .unknown: break
            }
        } else if let err = op.error {
            showAlert(with: err)
        }
    }
    
    private func resetErrorDisplay() {
        emailFieldView.isRejecting = false
        inputErrorLabel.text = nil
        inputErrorView.isHidden = true
    }
    
    private func showAlert(with error: Error) {
        if let err = error as? InputError {
            showInputError(with: err.localizedDescription)
        } else {
            resetErrorDisplay()
            let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func showInputError(with message: String) {
        emailFieldView.isRejecting = true
        inputErrorView.isHidden = false
        inputErrorLabel.text = message
    }
    
    private func updateViewsForRunningAuthOperation() {
        let allowsAction = authOperation == nil
        updateViewForInputChange()
        emailFieldView.textField.isEnabled = allowsAction
        socialLoginButtons.forEach { $0.isEnabled = allowsAction }
    }
    
    private func didLogIn() {
        let op = authOperation!
        authOperation = nil
        if let token = op.token {
            let session = UserSession(token: token)
            session.socialProfile = op.publicProfile
            StoreUserSessionOperation(session: session).start()
            performSegue(withIdentifier: SegueID.createProfile, sender: session)
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    @IBAction func next(_ sender: Any) {
        view.endEditing(false)
        emailAuthCredential.email = emailFieldView.textField.text ?? ""
        getAccountState()
    }
    
    @IBAction func facebookLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = FacebookLoginOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func twitterLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = TwitterLogInOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func weChatLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = WeChatLogInOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func updateEmailInput(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        emailAuthCredential.email = emailFieldView.textField.text ?? ""
    }
    
    @IBAction func endEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? EmailVerificationViewController {
            vc.emailAuthCredential = emailAuthCredential
            vc.flow = .signUp
            vc.needsSendVerificationLinkAutomatically = true
            vc.authorizationCompletion = {[weak self] session in
                self?.authorizationCompletion?(session)
            }
        }
        if let vc = segue.destination as? CreateProfileViewController {
            vc.userSession = (sender as! UserSession)
        }
    }

}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        endEditingTap.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditingTap.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(false)
        return false
    }
}

extension SignUpViewController {
    struct SegueID {
        static let emailVerification = "emailVerification"
        static let createProfile = "createProfile"
    }
}

class InputFieldView: UIView {
    @IBOutlet weak var normalBackgroundImage: UIImageView!
    @IBOutlet weak var rejectingBackgroundImage: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    var isRejecting = false {
        didSet {
            updateWithRejectingState()
        }
    }
    
    override func awakeFromNib() {
        updateWithRejectingState()
    }
    
    private func updateWithRejectingState() {
        if isRejecting {
            normalBackgroundImage.isHidden = true
            rejectingBackgroundImage.isHidden = false
        } else {
            normalBackgroundImage.isHidden = false
            rejectingBackgroundImage.isHidden = true

        }
    }
}
