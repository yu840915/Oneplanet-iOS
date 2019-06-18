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

    @IBOutlet weak var exitButtonItem: UIBarButtonItem!
    @IBOutlet weak var countryCodeField: UITextField!
    @IBOutlet weak var emailFieldBlock: InputFieldBlockView!
    @IBOutlet weak var firstNameFieldBlock: InputFieldBlockView!
    @IBOutlet weak var lastNameFieldBlock: InputFieldBlockView!
    @IBOutlet weak var address1FieldBlock: InputFieldBlockView!
    @IBOutlet weak var address2FieldBlock: InputFieldBlockView!
    @IBOutlet weak var cityFieldBlock: InputFieldBlockView!
    @IBOutlet weak var regionFieldBlock: InputFieldBlockView!
    @IBOutlet weak var postalCodeFieldBlock: InputFieldBlockView!
    @IBOutlet var numberInputToolbar: UIToolbar!
    @IBOutlet weak var countryFieldBlock: InputFieldBlockView!
    @IBOutlet weak var phonenumberFieldBlock: InputFieldBlockView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    
    private var keyboardObserver: KeyboardAppearanceObserver?
    private var tapToEndEditingRequestTracker: ReferenceTracker!
    private var fieldMap: [ShippingInfoDraft.Field: InputFieldBlockView] = [:]
    private var nextFieldMap: [ShippingInfoDraft.Field: ShippingInfoDraft.Field] = [
        .email: .firstName,
        .firstName: .lastName,
        .lastName: .address1,
        .address1: .address2,
        .address2: .city,
        .city: .region,
        .region: .postalCode,
        .country: .phoneNumber]
    var draft: ShippingInfoDraft!
    private var endEditingTapRequestHandle: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let builder = PhoneNumberBuilder(countryCode: nil)
        debugPrint(builder.countries)
        tapToEndEditingRequestTracker = ReferenceTracker()
        endEditingTapRequestHandle = tapToEndEditingRequestTracker.isEmptyDidChangeObservers.add {[weak self] (_) in
            self?.updateEndEditingTap()
        }
        fieldMap = [
            .email: emailFieldBlock,
            .firstName: firstNameFieldBlock,
            .lastName: lastNameFieldBlock,
            .address1: address1FieldBlock,
            .address2: address2FieldBlock,
            .city: cityFieldBlock,
            .region: regionFieldBlock,
            .postalCode: postalCodeFieldBlock,
            .country: countryFieldBlock,
            .phoneNumber: phonenumberFieldBlock
        ]
        localizeTitles()
        prepareForDraft()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
        let observer = KeyboardAppearanceObserver()
        observer.keyboardWillChange = {[weak self] change in
            self?.handleKeyboardChange(change)
        }
        keyboardObserver = observer
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardObserver = nil
    }

    @IBAction func checkAndSubmitForm(_ sender: UIButton) {
    }
    
    @IBAction func tapToEndEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
    
    @IBAction func exit(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismissNumberPad(_ sender: UIBarButtonItem) {
        view.endEditing(false)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? PickerTableViewController {
            vc.title = Localized.shippingInfoTerms.country
            vc.options = draft.phoneNumberBuilder.countries.map{CountryCodePickerItem(countryCode: $0)}
            if let country = draft.country {
                vc.selection = CountryCodePickerItem(countryCode: country)
            }
        }
    }
}

fileprivate extension ShippingInfoEditorViewController {
    func updateEndEditingTap() {
        endEditingTap.isEnabled = !tapToEndEditingRequestTracker.isEmpty
    }
    
    func localizeTitles() {
        title = Localized.phrases.shippingInfo
        exitButtonItem.title = Localized.titles.cancel
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
        doneButtonItem.title = Localized.titles.done
    }
    
    func prepareForDraft() {
        draft = ShippingInfoDraft()
        let fields: [ShippingInfoDraft.Field] = [.email, .firstName, .lastName, .address1, .address2, .city, .region, .postalCode, .phoneNumber]
        fields.forEach{prepareFieldBlock(for: $0)}
        draft.requiredFields.compactMap{fieldMap[$0]}.forEach{
            $0.placeholder = Localized.titles.requiredInput
        }
        let delegate = CountryInputFieldDelegate()
        delegate.showCountryPickerAction = {[weak self] in
            self?.performSegue(withIdentifier: SegueID.showCountryPicker, sender: nil)
        }
        countryFieldBlock.inputFieldDelegate = delegate
    }
    
    func prepareFieldBlock(for field: ShippingInfoDraft.Field) {
        let fieldBlock = fieldMap[field]!
        fieldBlock.fieldView.textField.text = draft[field]
        let delegate = ShippingInfoInputFieldDelegate()
        delegate.tapToEndEditingRequestTracker = tapToEndEditingRequestTracker
        delegate.inputValidator = draft.validatorPair(for: field).intermediate
        if let nextField = nextFieldMap[field] {
            delegate.nextInputBlock = fieldMap[nextField]
        }
        delegate.didEndEditing = {[weak self] textField in
            self?.draft[field] = textField.text ?? ""
        }
        fieldBlock.inputDidChange = {[weak self] textField in
            self?.draft[field] = textField.text ?? ""
        }
        fieldBlock.inputFieldDelegate = delegate
    }
    
    func handleKeyboardChange(_ change: KeyboardChangeInfo) {
        let isAppearing = view.bounds.intersects(change.endRect)
        additionalSafeAreaInsets.bottom = isAppearing ? change.endRect.height : 0
    }
}

extension ShippingInfoEditorViewController {
    struct SegueID {
        static let showCountryPicker = "showCountryPicker"
    }
}
