//
//  EmailVerificationViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class EmailVerificationViewController: UIViewController {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var actionTextView: UITextView!
    
    var flow: Flow!
    var credential: EmailAuthCredential!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        prepareMessageLabel()
        prepareActionTextView()
    }
    
    private func prepareMessageLabel() {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 33
        messageLabel.attributedText = NSAttributedString(string: Localized.messages.emailVerificationInstruction, attributes: [.paragraphStyle : style])
    }
    
    private func prepareActionTextView() {
        let text = String(format: Localized.messageFormats.resendVerificationEmail, Localized.phrases.resendEmail)
        let actionRange = (text as NSString).range(of: Localized.phrases.resendEmail)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText])
        attrStr.addAttributes([.link : "https://www.apple.com"], range: actionRange)
        actionTextView.attributedText = attrStr
        actionTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    fileprivate func resendEmailIfAllowed() {
        
    }

    @IBAction func invokeExitAction(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
    }
    
}

extension EmailVerificationViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        resendEmailIfAllowed()
        return false
    }
}

extension EmailVerificationViewController {
    struct SegueID {
        static let signUp = "signUpPassword"
        static let logIn = "logInPassword"
    }
    enum Flow {
        case signUp
        case logIn
        
        var segueID: String {
            switch self {
            case .signUp: return SegueID.signUp
            case .logIn: return SegueID.logIn
            }
        }
    }
}
