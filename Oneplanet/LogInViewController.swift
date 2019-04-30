//
//  LogInViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class LogInViewController: UIViewController {
    
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!

    private var getUserVerificationStateOperation: GetAccountStateOperation?
    private(set) var emailAuthCredential: EmailAuthCredential!
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
        emailLoginLabel.text = Localized.phrase.or
        emailFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.email, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        nextButton.setTitle(Localized.titles.next, for: .normal)
    }

    private func updateViewForInputChange() {
        nextButton.isEnabled = !emailAuthCredential.email.isEmpty
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? EmailVerificationViewController {
            vc.credential = emailAuthCredential
            vc.flow = .logIn
        }
    }
}

extension LogInViewController {
    struct SegueID {
        static let emailVerification = "emailVerification"
    }

}
