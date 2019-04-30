//
//  LoginPasswordViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LoginPasswordViewController: UIViewController {

    @IBOutlet weak var inputFieldView: InputFieldView!
    @IBOutlet weak var forgetPasswordButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
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
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
