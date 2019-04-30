//
//  SignUpPasswordViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SignUpPasswordViewController: UIViewController, EmailAuthFlowStep {
    
    var emailAuthCredential: EmailAuthCredential!
    var authorizationCompletion: ((UserSession) -> ())!
    @IBOutlet weak var passwordRuleLabel: UILabel!
    @IBOutlet weak var inputFieldView: InputFieldView!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        navigationItem.hidesBackButton = true
    }

    private func localizeTitles() {
        title = Localized.titles.signUp
        signUpButton.setTitle(Localized.titles.next, for: .normal)
        passwordRuleLabel.text = Localized.messages.passwordRules
        inputFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.password, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
    }
}
