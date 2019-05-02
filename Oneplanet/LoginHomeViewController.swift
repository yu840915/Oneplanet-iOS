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
    private var requestNotificationAuthorizationOperation: RequestUserNotificationAuthorizationOperation?
    private var authOperation: AuthenticationOperationType? {
        didSet {
            updateViewsForRunningAuthOperation()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        localizeTitles()
        prepareTermsTextView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestNotificationAuthorization()
        router.resume()
    }
    
    private func localizeTitles() {
        signUpButton.setTitle(Localized.titles.signUp, for: .normal)
        logInButton.setTitle(Localized.titles.logIn, for: .normal)
        loginPromptLabel.text = Localized.messages.loginPrompt
        guestLoginButton.setTitle(Localized.phrases.geustLogin, for: .normal)
    }
    
    private func prepareTermsTextView() {
        let text = String(format: Localized.messageFormats.acceptTOS, Localized.titles.tos)
        let tosRange = (text as NSString).range(of: Localized.titles.tos)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.addAttributes([.link : "https://www.google.com"], range: tosRange)
        termsTextView.attributedText = attrStr
        termsTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.defaultText,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    fileprivate func showTermsPage(with url: URL) {
        performSegue(withIdentifier: SegueID.showTerms, sender: URLRequest(url: url))
    }
    
    private func requestNotificationAuthorization() {
        guard requestNotificationAuthorizationOperation == nil else {
            return
        }
        let op = RequestUserNotificationAuthorizationOperation()
        requestNotificationAuthorizationOperation = op
        op.start()
    }
    
    private func updateViewsForRunningAuthOperation() {
        let allowsAction = authOperation == nil
        logInButton.isEnabled = allowsAction
        signUpButton.isEnabled = allowsAction
        guestLoginButton.isEnabled = allowsAction
        termsTextView.isSelectable = allowsAction
    }
    
    @IBAction func guestLogIn(_ sender: Any) {
        guard authOperation == nil else { return }
        let op = GuestLogInOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    private func didLogIn() {
        let op = authOperation!
        authOperation = nil
        if let token = op.token {
            authorizationCompletion?(UserSession(token: token))
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? WebViewController {
            NavigationBarStyle.darkGrey.configure(nav.navigationBar)
            vc.request = sender as? URLRequest
            vc.title = Localized.titles.tos
        }
    }

}

extension LoginHomeViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.showTermsPage(with: URL)
        }
        return false
    }
}

extension LoginHomeViewController {
    struct SegueID {
        static let showTerms = "showTerms"
    }
}
