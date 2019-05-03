//
//  LogInViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class LogInViewController: UIViewController, EmailAuthFlowStep {
    
    @IBOutlet var socialLoginButtons: [UIButton]!
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
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
    
    private func localizeTitles() {
        title = Localized.titles.logIn
        emailLoginLabel.text = Localized.phrases.or
        emailFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.email, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        nextButton.setTitle(Localized.titles.next, for: .normal)
    }

    private func updateViewForInputChange() {
        let allowsAction = authOperation == nil
        nextButton.isEnabled = allowsAction && !emailAuthCredential.email.isEmpty
    }
    
    private func updateViewsForRunningAuthOperation() {
        let allowsAction = authOperation == nil
        updateViewForInputChange()
        emailFieldView.textField.isEnabled = allowsAction
        socialLoginButtons.forEach { $0.isEnabled = allowsAction }
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
            case .verified:
                performSegue(withIdentifier: SegueID.showPasswordField, sender: emailAuthCredential)
            case .pending:
                performSegue(withIdentifier: SegueID.emailVerification, sender: emailAuthCredential)
            case .nonexist:
                showAccountError()
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
    
    private func showAccountError() {
        let alert = UIAlertController(title: Localized.errorTitles.accountDoesnotExist, message: Localized.errors.accountDoesnotExist, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.phrases.tryAgain, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showInputError(with message: String) {
        emailFieldView.isRejecting = true
        inputErrorView.isHidden = false
        inputErrorLabel.text = message
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

    private func didLogIn() {
        let op = authOperation!
        authOperation = nil
        if let token = op.token {
            let session = UserSession(token: token)
            session.socialProfile = op.publicProfile
            StoreUserSessionOperation(session: session).start()
            authorizationCompletion?(session)
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
    
    @IBAction func endEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    @IBAction func updateEmailInput(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        emailAuthCredential.email = emailFieldView.textField.text ?? ""
    }
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? EmailAuthFlowStep {
            vc.emailAuthCredential = emailAuthCredential
            vc.authorizationCompletion = {[weak self] session in
                self?.authorizationCompletion?(session)
            }
        }
        if let vc = segue.destination as? EmailVerificationViewController {
            vc.flow = .logIn
        }
    }
}

extension LogInViewController: UITextFieldDelegate {
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

extension LogInViewController {
    struct SegueID {
        static let emailVerification = "emailVerification"
        static let showPasswordField = "showPasswordField"
    }

}
