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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        title = Localized.titles.logIn
        loginButton.setTitle(Localized.titles.logIn, for: .normal)
        forgetPasswordButton.setTitle(Localized.phrases.forgetPassword, for: .normal)
        inputFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.password, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
    }

    @IBAction func requirResetPasswordIfAllowed(_ sender: UIButton) {
        let alert = UIAlertController(title: Localized.messages.sendResetLinkPrompt, message: Localized.messages.sendResetLinkDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: {[weak self] (_) in
            self?.sendResetLink()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func sendResetLink() {
        guard resetPasswordOperation == nil else { return }
        let op = SendResetPasswordLinkOperation(email: emailAuthCredential.email)
        op.completionBlock = {[weak self] in
            
        }
        resetPasswordOperation = op
        op.start()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}
