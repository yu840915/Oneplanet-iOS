//
//  PetitionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Alamofire

class PetitionViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionInputView: UITextView!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var draft: String = "" {
        didSet {
            if isViewLoaded {
                submitButton.isEnabled = !draft.isEmpty
            }
        }
    }
    private var submitOperation: SubmitPetitionOperation?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.phrases.recoverAccount
        cancelButtonItem.title = Localized.titles.cancel
        headerLabel.text = Localized.messages.recoverAccountDescription
        contentLabel.text = Localized.titles.content
        submitButton.setTitle(Localized.titles.send, for: .normal)
        submitButton.isEnabled = !draft.isEmpty
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
    }

    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    @IBAction func submit(_ sender: UIButton) {
        guard submitOperation == nil && !draft.isEmpty else {
            return
        }
        let op = SubmitPetitionOperation(petition: draft, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSubmitPetition()
            }
        }
        submitOperation = op
        op.start()
    }
    
    private func didSubmitPetition() {
        let op = submitOperation!
        submitOperation = nil
        if op.success == true {
            dismiss(animated: true) {
                let alert = UIAlertController(title: Localized.phrases.petitionSubmitted, message: Localized.messages.petitionSubmitted, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localized.phrases.iGetIt, style: .default, handler: nil))
                FrontViewControllerFinder.findFront()!.present(alert, animated: true, completion: nil)
            }
        } else if let error = op.error {
            showFailureAlert(for: error)
        }
    }
    
    private func showFailureAlert(for error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension PetitionViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard textView.markedTextRange == nil else { return }
        draft = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = false
    }

}

class SubmitPetitionOperation: AlamofireAPIAccessOperation {
    let petition: String
    let session: UserSession
    
    init(petition: String, session: UserSession) {
        self.petition = petition
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("me/apply/unbanned"), method: .post, parameters: ["message": petition], encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}
