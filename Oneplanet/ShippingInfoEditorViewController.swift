//
//  ShippingInfoEditorViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class ShippingInfoEditorViewController: UIViewController {

    @IBOutlet weak var countryCodeField: UITextField!
    @IBOutlet weak var emailFieldBlock: InputFieldBlockView!
    @IBOutlet weak var firstNameFieldBlock: InputFieldBlockView!
    @IBOutlet weak var lastNameFieldBlock: InputFieldBlockView!
    @IBOutlet weak var address1FieldBlock: InputFieldBlockView!
    @IBOutlet weak var address2FieldBlock: InputFieldBlockView!
    @IBOutlet weak var cityFieldBlock: InputFieldBlockView!
    @IBOutlet weak var regionFieldBlock: InputFieldBlockView!
    @IBOutlet weak var postalCodeFieldBlock: InputFieldBlockView!
    @IBOutlet weak var countryFieldBlock: InputFieldBlockView!
    @IBOutlet weak var phonenumberFieldBlock: InputFieldBlockView!
    @IBOutlet weak var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        title = Localized.phrases.shippingInfo
        submitButton.setTitle(Localized.titles.ok, for: .normal)
        emailFieldBlock.title = Localized.shippingInfoTerms.email
        firstNameFieldBlock.title = Localized.shippingInfoTerms.firstName
        lastNameFieldBlock.title = Localized.shippingInfoTerms.lastName
        address1FieldBlock.title = Localized.shippingInfoTerms.address1
        address2FieldBlock.title = Localized.shippingInfoTerms.address2
        cityFieldBlock.title = Localized.shippingInfoTerms.city
        regionFieldBlock.title = Localized.shippingInfoTerms.region
        postalCodeFieldBlock.title = Localized.shippingInfoTerms.postalCode
        countryFieldBlock.title = Localized.shippingInfoTerms.country
        phonenumberFieldBlock.title = Localized.shippingInfoTerms.phoneNumber
        [firstNameFieldBlock, firstNameFieldBlock, lastNameFieldBlock, address1FieldBlock, cityFieldBlock, regionFieldBlock, postalCodeFieldBlock, countryFieldBlock].forEach {
            $0?.fieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.titles.requiredInput, attributes: [.foregroundColor : ColorPalette.defaultPlaceholder])
        }
    }

    @IBAction func checkAndSubmitForm(_ sender: UIButton) {
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

class InputFieldBlockView: UIStackView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var fieldView: InputFieldView!
    
    var inputDidChange: ((UITextField)->())?
    var inputFieldDelegate: UITextFieldDelegate? {
        didSet {
            fieldView.textField.delegate = inputFieldDelegate
        }
    }
    var title: String? {
        set {
            titleLabel.text = newValue
        }
        get {
            return titleLabel.text
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        fieldView.textField.addTarget(self, action: #selector(notifyInputChange(_:)), for: .editingChanged)
    }
    
    func showInputError(with message: String) {
        fieldView.isRejecting = true
        errorView.isHidden = false
        errorLabel.text = message
    }

    func resetErrorDisplay() {
        fieldView.isRejecting = false
        errorLabel.text = nil
        errorView.isHidden = true
    }
    
    @IBAction func notifyInputChange(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        inputDidChange?(sender)
    }
}

class ShippingInfoInputFieldDelegate: NSObject, UITextFieldDelegate {
    var nextInputBlock: InputFieldBlockView?
    var tapToEndEditingRequestTracker: ReferenceTracker?
    var didEndEditing: ((UITextField)->())?
    private var tapToEndEditingRequest: Any?
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tapToEndEditingRequest = tapToEndEditingRequestTracker?.add()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        tapToEndEditingRequest = nil
        didEndEditing?(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let next = nextInputBlock {
            next.fieldView.textField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let result = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if result.isEmpty {
            return true
        }
        do {
            if result.isEmpty {
                return true
            }
            return true
        } catch _  {
            return false
        }
    }
}
