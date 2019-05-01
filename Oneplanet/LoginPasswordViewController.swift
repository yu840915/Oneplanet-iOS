//
//  LoginPasswordViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LoginPasswordViewController: UIViewController, EmailAuthFlowStep {
    
    var emailAuthCredential: EmailAuthCredential!
    var authorizationCompletion: ((UserSession) -> ())!
    @IBOutlet weak var inputFieldView: InputFieldView!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    private var resetPasswordOperation: SendResetPasswordLinkOperation?
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var updateHandle: Any?
    private var eventHandles: [Any]?
    private var logInOperaion: EmailLogInOperarion?
    private var session: UserSession?

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        emailAuthCredential.password = ""
        registerEvents()
        updateViewsForInputChange()
    }
    
    private func updateViewsForInputChange() {
        loginButton.isEnabled = emailAuthCredential.isValid
    }
    
    private func localizeTitles() {
        title = Localized.titles.logIn
        loginButton.setTitle(Localized.titles.logIn, for: .normal)
        forgetPasswordButton.setTitle(Localized.phrases.forgetPassword, for: .normal)
        inputFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.password, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
    }
    
    private func registerEvents() {
        var handles = [Any]()
        handles.append(emailAuthCredential.inputDidChangeHandlers.add {[weak self] in
            self?.updateViewsForInputChange()
        })
        handles.append(AppLifeCycleObserver.willEnterForeground.observers.add {[weak self] (_) in
            self?.cancelResetPasswordIfNeeded()
        })
        handles.append(AppLifeCycleObserver.didBecomeActive.observers.add({[weak self] (_) in
            OperationQueue.main.addOperation {
                self?.updateViewsForRunningActions()
            }
        }))
        eventHandles = handles
    }
    
    private func cancelResetPasswordIfNeeded() {
        resetPasswordOperation?.cancel()
        resetPasswordOperation = nil
    }
    
    private func updateViewsForRunningActions() {
        forgetPasswordButton.isEnabled = (resetPasswordOperation == nil)
    }
    
    private func logIn() {
        guard logInOperaion == nil else {return}
        let op = EmailLogInOperarion(credential: emailAuthCredential)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogIn()
            }
        }
        logInOperaion = op
        op.start()
    }
    
    private func didLogIn() {
        let op = logInOperaion!
        logInOperaion = nil
        if let token = op.token {
            prepareSessionAndNotify(with: token)
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func prepareSessionAndNotify(with token: String) {
        let session = UserSession(token: token)
        self.session = session
        StoreUserSessionOperation(session: session).start()
        authorizationCompletion?(session)
    }
    
    private func sendResetLink() {
        guard resetPasswordOperation == nil else { return }
        let op = SendResetPasswordLinkOperation(email: emailAuthCredential.email)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSendResetLink()
            }
        }
        resetPasswordOperation = op
        op.start()
        updateViewsForRunningActions()
    }
    
    private func didSendResetLink() {
        let op = resetPasswordOperation!
        if op.success == false {
            resetPasswordOperation = nil
            if let error = op.error {
                showAlert(with: error)
            }
        }
        updateViewsForRunningActions()
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func logIn(_ sender: UIButton) {
        view.endEditing(false)
        emailAuthCredential.password = inputFieldView.textField.text ?? ""
        logIn()
    }
    
    @IBAction func updatePassword(_ sender: UITextField) {
        emailAuthCredential.password = inputFieldView.textField.text ?? ""
    }
    
    @IBAction func requirResetPasswordIfAllowed(_ sender: UIButton) {
        let alert = UIAlertController(title: Localized.messages.sendResetLinkPrompt, message: Localized.messages.sendResetLinkDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: {[weak self] (_) in
            self?.sendResetLink()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func endEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}

extension LoginPasswordViewController: UITextFieldDelegate {
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let result = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if result.isEmpty {
            return true
        }
        do {
            if result.isEmpty {
                return true
            }
            try InputValidators.intermediatePassword.validate(result)
            return true
        } catch _  {
            return false
        }
    }
}
