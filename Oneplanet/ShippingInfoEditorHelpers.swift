//
//  ShippingInfoEditorHelpers.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/18.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class InputFieldBlockView: UIStackView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var fieldView: InputFieldView!
    
    var placeholder: String = "" {
        didSet {
            if oldValue != placeholder {
                preparePlaceholder()
            }
        }
    }
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
    
    private func preparePlaceholder() {
        guard !placeholder.isEmpty else {
            fieldView.textField.attributedPlaceholder = nil
            return
        }
        fieldView.textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor : ColorPalette.defaultPlaceholder])
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
    var inputValidator: TextInputValidator?
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
            try inputValidator?.validate(result)
            return true
        } catch _  {
            return false
        }
    }
}

class CountryInputFieldDelegate: ShippingInfoInputFieldDelegate {
    var showCountryPickerAction: (()->())?
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showCountryPickerAction?()
        return false
    }
    
    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}

class CountryCodePickerItem: PickerItemDisplayable {
    let countryCode: CountryCode
    
    init(countryCode: CountryCode) {
        self.countryCode = countryCode
    }
    
    var mainTitle: String {
        return countryCode.displayName() ?? ""
    }
    var detailTitle: String? {
        return countryCode.cellPhoneContryCode
    }
    
    func isEqual(to item: PickerItemDisplayable) -> Bool {
        guard let other = item as? CountryCodePickerItem else {
            return false
        }
        return other.countryCode == countryCode
    }
}
