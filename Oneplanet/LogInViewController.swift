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
    
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!

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
        nextButton.isEnabled = !emailAuthCredential.email.isEmpty
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

    @IBAction func next(_ sender: Any) {
        emailAuthCredential.email = emailFieldView.textField.text ?? ""
        getAccountState()
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
