//
//  LoginHomeViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol AuthorizationFlowEntryPoint: AnyObject {
    var authorizationCompletion: ((UserSession)->())! {set get}
}

class LoginHomeViewController: UIViewController, AuthorizationFlowEntryPoint {
    var authorizationCompletion: ((UserSession) -> ())!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginPromptLabel: UILabel!
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var guestLoginButton: UIButton!
    @IBOutlet weak var termsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        localizeTitles()
        prepareTermsTextView()
    }
    
    private func localizeTitles() {
        signUpButton.setTitle(Localized.titles.signUp, for: .normal)
        logInButton.setTitle(Localized.titles.logIn, for: .normal)
        loginPromptLabel.text = Localized.messages.loginPrompt
        guestLoginButton.setTitle(Localized.phrase.geustLogin, for: .normal)
    }
    
    private func prepareTermsTextView() {
        let text = String(format: Localized.messageFormats.acceptTOS, Localized.titles.tos)
        let tosRange = (text as NSString).range(of: Localized.titles.tos)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.addAttributes([.link : "https://www.apple.com"], range: tosRange)
        termsTextView.attributedText = attrStr
        termsTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.defaultText,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    fileprivate func showWebPage(for url: URL) {
        
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}

extension LoginHomeViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.showWebPage(for: URL)
        }
        return false
    }
}
