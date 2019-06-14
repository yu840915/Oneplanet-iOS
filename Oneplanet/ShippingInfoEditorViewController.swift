//
//  ShippingInfoEditorViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        title = Localized.phrases.shippingInfo
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
    var inputFieldDelegate: UITextFieldDelegate? {
        didSet {
            fieldView.textField.delegate = inputFieldDelegate
        }
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
}
