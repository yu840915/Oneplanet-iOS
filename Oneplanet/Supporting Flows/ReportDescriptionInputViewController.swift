//
//  ReportDescriptionInputViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ReportDescriptionInputViewController: UIViewController {
    @IBOutlet weak var reasonLabel: UILabel!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionInputView: UITextView!
    @IBOutlet weak var reportLabel: UILabel!
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    
    var didFinishReport: (()->())?
    var draft: ReportDraft!
    var flowController: ReportFlowController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Localized.titles.report
        reportButton.setTitle(Localized.titles.report, for: .normal)
        reportLabel.text = flowController.reportCaption
        placeholderLabel.text = Localized.placeholder.reportDescription
        let reason = draft.reason!
        if reason.detail.isEmpty {
            reasonLabel.isHidden = true
            headerLabel.text = flowController.headerTitle
        } else {
            headerLabel.isHidden = true
            reasonLabel.text = reason.detail
        }
        updateInteractionForStates()
        draft.didUpdate = {[weak self] in
            self?.updateInteractionForStates()
        }
        updatePlaceholderAppearance()
    }
    
    private func updateInteractionForStates() {
        let allowsSubmit = draft.isReady && !flowController.isReporting
        reportButton.isEnabled = allowsSubmit
        descriptionInputView.isEditable = !flowController.isReporting
    }
    
    @IBAction func reportIfReady(_ sender: UIButton) {
        guard draft.isReady else {
            return
        }
        view.endEditing(false)
        flowController.submit(draft) { (success, error) in
            OperationQueue.main.addOperation {
                self.handleSubmitReport(success, error: error)
            }
        }
        updateInteractionForStates()
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    private func handleSubmitReport(_ success: Bool, error: Error?) {
        if success {
            if flowController.shouldShowThankYouPage {
                performSegue(withIdentifier: SegueID.showThankPage, sender: nil)
            } else {
                dismiss(animated: true, completion: nil)
            }
            didFinishReport?()
        } else if let error = error {
            showAlert(for: error)
        }
        updateInteractionForStates()
    }
    
    private func showAlert(for error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension ReportDescriptionInputViewController {
    struct SegueID {
        static let showThankPage = "showThankPage"
    }
}

extension ReportDescriptionInputViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderAppearance()
        guard textView.markedTextRange == nil else { return }
        draft.description = textView.text
    }
    
    private func updatePlaceholderAppearance() {
        let hasText = descriptionInputView.text.isEmpty == false
        placeholderLabel.isHidden = hasText
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = false
    }
}
