//
//  LogInViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

protocol AuthorizationFlowEntryPoint: AnyObject {
    var authorizationCompletion: ((UserSession)->())! {set get}
}

protocol EmailAuthFlowStep: AnyObject {
    var emailAuthCredential: EmailAuthCredential! {set get}
    var authorizationCompletion: ((UserSession)->())! {set get}
}

class LogInViewController: UIViewController, EmailAuthFlowStep, AuthorizationFlowEntryPoint {
    
    @IBOutlet var socialLoginButtons: [UIButton]!
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var guestLoginButton: UIButton!
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var loginRounter: URLRouter!
    private var session: UserSession?

    private var requestNotificationAuthorizationOperation: RequestUserNotificationAuthorizationOperation?
    private var authOperation: AuthenticationOperationType? {
        didSet {
            updateViewsForRunningAuthOperation()
        }
    }
    private var sendEmailLinkOperation: SendEmailLinkOperation? {
        didSet {
            updateViewsForRunningAuthOperation()
        }
    }
    private weak var emailVerificationViewController: EmailVerificationViewController?
    var emailAuthCredential: EmailAuthCredential!
    var authorizationCompletion: ((UserSession) -> ())!
    private var inputChangeHandle: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        navigationItem.hidesBackButton = true
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        localizeTitles()
        prepareTermsTextView()
        emailAuthCredential = EmailAuthCredential()
        setUpEmailLinkLoginHandler()
        inputChangeHandle = emailAuthCredential.inputDidChangeHandlers.add {[weak self] in
            self?.updateViewForInputChange()
        }
        updateViewForInputChange()
    }
    
    deinit {
        router.removeOverridingRouter(loginRounter)
    }
    
    private func setUpEmailLinkLoginHandler() {
        let loginRouter = URLRouter()
        loginRouter.add("/login/email") {[weak self] (info) -> Bool in
            return self?.startEmailLinkLogInIfAllowed(with: info) ?? false
        }
        self.loginRounter = loginRouter
        router.addOverridingRouter(loginRounter)
    }
    
    private func startEmailLinkLogInIfAllowed(with info: [String: Any]) -> Bool {
        guard session == nil, authOperation == nil else { return false }
        guard let url = info[URLRouter.Keys.url] as? URL else { return false }
        OperationQueue.main.addOperation {
            self.logIn(withEmailLink: url)
        }
        return true
    }
    
    private func logIn(withEmailLink url: URL) {
        emailAuthCredential.magicLink = url
        let op = EmailLinkLogInOperarion(credential: emailAuthCredential)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogInWithEmailLink()
            }
        }
        authOperation = op
        op.start()
    }
    
    private func didLogInWithEmailLink() {
        let op = authOperation!
        authOperation = nil
        if let token = op.token {
            let session = UserSession(token: token)
            session.updateProfile(op.profile!)
            StoreUserSessionOperation(session: session).start()
            if let vc = emailVerificationViewController {
                vc.startPreflightCheck(with: session)
                self.session = session
            } else {
                startPreflightCheck(with: session)
            }
        } else if let error = op.error {
            if let vc = emailVerificationViewController {
                vc.showAlert(with: error)
            } else {
                showAlert(with: error)
            }
        }

    }
    
    private func localizeTitles() {
        emailLoginLabel.text = Localized.phrases.emailLogin
        emailFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.email, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        nextButton.setTitle(Localized.titles.logIn, for: .normal)
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
    
    private func updateViewForInputChange() {
        let allowsAction = authOperation == nil && sendEmailLinkOperation == nil
        nextButton.isEnabled = allowsAction && !emailAuthCredential.email.isEmpty
    }
    
    private func updateViewsForRunningAuthOperation() {
        let allowsAction = authOperation == nil
        updateViewForInputChange()
        emailFieldView.textField.isEnabled = allowsAction
        socialLoginButtons.forEach { $0.isEnabled = allowsAction }
        guestLoginButton.isEnabled = allowsAction
        termsTextView.isSelectable = allowsAction
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestNotificationAuthorization()
        router.resume()
    }

    private func requestNotificationAuthorization() {
        guard requestNotificationAuthorizationOperation == nil else {
            return
        }
        let op = RequestUserNotificationAuthorizationOperation()
        requestNotificationAuthorizationOperation = op
        op.start()
    }

    private func sendEmailLink() {
        guard sendEmailLinkOperation == nil else {
            return
        }
        let op = SendEmailLinkOperation(email: emailAuthCredential.email)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSendEmailLink()
            }
        }
        sendEmailLinkOperation = op
        op.start()
    }
    
    private func didSendEmailLink() {
        let op = sendEmailLinkOperation!
        sendEmailLinkOperation = nil
        resetErrorDisplay()
        if op.success == true {
            performSegue(withIdentifier: SegueID.emailVerification, sender: emailAuthCredential)
        } else if let err = op.error {
            showAlert(with: err)
        }
    }

    private func resetErrorDisplay() {
        emailFieldView.isRejecting = false
        inputErrorLabel.text = nil
        inputErrorView.isHidden = true
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

    private func didSocialLogIn() {
        let op = authOperation!
        authOperation = nil
        if let error = op.error {
            showAlert(with: error)
        } else if let token = op.token {
            let session = UserSession(token: token)
            session.updateProfile(op.profile!)
            if let socialAuth = op as? SocialAuthenticationOperationType {
                session.socialProfile = socialAuth.publicProfile
            }
            StoreUserSessionOperation(session: session).start()
            startPreflightCheck(with: session)
        }
    }
    
    private func startPreflightCheck(with session: UserSession) {
        self.session = session
        performSegue(withIdentifier: SegueID.preflightCheck, sender: session)
    }
    

    @IBAction func next(_ sender: Any) {
        view.endEditing(false)
        emailAuthCredential.email = emailFieldView.textField.text ?? ""
        sendEmailLink()
    }
    
    @IBAction func facebookLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = FacebookLoginOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSocialLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func twitterLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = TwitterLogInOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSocialLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func weChatLogIn(_ sender: UIButton) {
        guard authOperation == nil else { return }
        let op = WeChatLogInOperation(presenter: self)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSocialLogIn()
            }
        }
        authOperation = op
        op.start()
    }
    
    @IBAction func guestLogIn(_ sender: Any) {
        guard authOperation == nil else { return }
        let op = GuestLogInOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didLogInAsGuest()
            }
        }
        authOperation = op
        op.start()
    }
    
    private func didLogInAsGuest() {
        let op = authOperation!
        authOperation = nil
        if let token = op.token {
            authorizationCompletion?(UserSession(token: token))
        } else if let error = op.error {
            showAlert(with: error)
        }
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
                self?.authorizationCompletion(session)
            }
        }
        if let vc = segue.destination as? EmailVerificationViewController {
            emailVerificationViewController = vc
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? WebViewController {
            NavigationBarStyle.darkGrey.configure(nav.navigationBar)
            vc.request = sender as? URLRequest
            vc.title = Localized.titles.tos
        }
        if let nav = segue.destination as? UINavigationController, let vc = nav.viewControllers.first as? PreflightCheckFlowViewController {
            vc.userSession = (sender as! UserSession)
            vc.didFinishPreflightCheck = {[weak self] in
                self?.authorizationCompletion(sender as! UserSession)
            }
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

extension LogInViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.showTermsPage(with: URL)
        }
        return false
    }
}

extension LogInViewController {
    struct SegueID {
        static let emailVerification = "emailVerification"
        static let showTerms = "showTerms"
        static let preflightCheck = "preflightCheck"
    }

}

