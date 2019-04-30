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
    private var getAccountStateOperation: GetAccountStateOperation?
    private var needsGetAccountState = false
    private var resendEmailOperation: Operation?
    private var eventHandles: [Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        prepareMessageLabel()
        prepareActionTextView()
        registerEvents()
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
    
    private func registerEvents() {
        var handles = [Any]()
        handles.append(AppLifeCycleObserver.willEnterForeground.observers.add {[weak self] (_) in
            self?.prepareForNextVerificationRound()
        })
        handles.append(AppLifeCycleObserver.didBecomeActive.observers.add({[weak self] (_) in
            self?.getAccountStateIfNeeded()
        }))
        eventHandles = handles
    }
    
    fileprivate func resendEmailIfAllowed() {
        guard resendEmailOperation == nil else { return }
    }
    
    fileprivate func didResendEmail() {
        //if no, clear op
    }
    
    private func prepareForNextVerificationRound() {
        needsGetAccountState = true
        resendEmailOperation = nil
    }
    
    private func getAccountStateIfNeeded() {
        guard needsGetAccountState && getAccountStateOperation == nil else {
            return
        }
        needsGetAccountState = false
        let op = GetAccountStateOperation(email: credential.email)
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
            switch op.state {
            case .verified:
                performSegue(withIdentifier: flow.segueID, sender: nil)
            case .pending: break
            case .nonexist: navigationController?.popToRootViewController(animated: true)
            case .unknown: break
            }
        } else if let err = op.error {
            logger.debug("Cannot verify email, error \(err)")
        }
    }
    
    @IBAction func exit(_ sender: UIBarButtonItem) {
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
