//
//  SignUpPasswordViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class SignUpPasswordViewController: UIViewController, EmailAuthFlowStep {
    
    var emailAuthCredential: EmailAuthCredential!
    var authorizationCompletion: ((UserSession) -> ())!
    @IBOutlet weak var passwordRuleLabel: UILabel!
    @IBOutlet weak var inputFieldView: InputFieldView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var updateHandle: Any?
    private var signUpOperaion: EmailSignUpOperarion?
    private var session: UserSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        navigationItem.hidesBackButton = true
        updateHandle = emailAuthCredential.inputDidChangeHandlers.add {[weak self] in
            self?.updateViewsForInputChange()
        }
        updateViewsForInputChange()
    }
    
    private func updateViewsForInputChange() {
        signUpButton.isEnabled = emailAuthCredential.isValid
    }

    private func localizeTitles() {
        title = Localized.titles.signUp
        signUpButton.setTitle(Localized.titles.next, for: .normal)
        passwordRuleLabel.text = Localized.messages.passwordRules
        inputFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.password, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
    }
    
    private func signUp() {
        guard signUpOperaion == nil else {
            return
        }
        let op = EmailSignUpOperarion(credential: emailAuthCredential)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSignUp()
            }
        }
        signUpOperaion = op
        op.start()
    }
    
    private func didSignUp() {
        let op = signUpOperaion!
        signUpOperaion = nil
        if let token = op.token {
            prepareSessionAndCreateProfile(with: token)
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func prepareSessionAndCreateProfile(with token: String) {
        let session = UserSession(token: token)
        self.session = session
        StoreUserSessionOperation(session: session).start()
        performSegue(withIdentifier: SegueID.createProfile, sender: session)
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func notifyAuthorizationCompletion() {
        guard let session = self.session else { return }
        authorizationCompletion?(session)
    }
    
    @IBAction func signUp(_ sender: UIButton) {
        view.endEditing(false)
        emailAuthCredential.password = inputFieldView.textField.text ?? ""
        signUp()
    }
    
    @IBAction func updatePassword(_ sender: UITextField) {
        emailAuthCredential.password = inputFieldView.textField.text ?? ""
    }
    
    @IBAction func endEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CreateProfileViewController {
            vc.didCreateProfile = {[weak self] in
                self?.notifyAuthorizationCompletion()
            }
            vc.userSession = (sender as! UserSession)
        }
    }
}

extension SignUpPasswordViewController: UITextFieldDelegate {
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
            try InputValidators.intermediatePassword.validate(result)
            return true
        } catch _  {
            return false
        }
    }
}

extension SignUpPasswordViewController {
    struct SegueID {
        static let createProfile = "createProfile"
    }
}
