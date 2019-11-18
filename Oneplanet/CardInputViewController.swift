//
//  CardInputViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/11/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import TPDirect
import ModelBlocks

class CardInputViewController: UIViewController, UserSessionDepending {

    var userSession: UserSession!
    var plan: IAPProductPlan!
    var successHandler: (()->())?
    
    @IBOutlet weak var cardholderFieldView: CardInfoInputView!
    @IBOutlet weak var emailFieldView: CardInfoInputView!
    @IBOutlet weak var countryFieldView: CardInfoInputView!
    @IBOutlet weak var phoneFieldView: CardInfoInputView!
    
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    var cardForm : TPDForm!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    private var keyboardObserver: KeyboardAppearanceObserver?
    @IBOutlet var endEditingTap: UITapGestureRecognizer!

    private var buyRubyOperation: BuyRubyFlowOperation? {
        didSet {
            updateBuyButton()
        }
    }
    private var lastStatus: TPDStatus?
    private var tapToEndEditingRequestTracker: ReferenceTracker!
    private var endEditingTapRequestHandle: Any?
    private var draftUpdateHandle: Any!
    private var draft: CardholderInfoDraft!

    override func viewDidLoad() {
        super.viewDidLoad()
        draft = CardholderInfoDraft()
        draftUpdateHandle = draft.updateObservers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateBuyButton()
            }
        }
        cancelItem.title = Localized.titles.cancel
        if plan.bonus > 0 {
            productNameLabel.text = String(format: Localized.phraseFormats.buySomeGetSomeFree, SharedNumberFormatters.integer.string(for: plan.amount)!, SharedNumberFormatters.integer.string(for: plan.bonus)!)
        } else {
            productNameLabel.text = String(format: Localized.phraseFormats.buySome, SharedNumberFormatters.integer.string(for: plan.amount)!)
        }
        buyButton.isEnabled = false
        let priceTag = plan.priceTag!.currency + " " + SharedNumberFormatters.price.string(for: plan.priceTag!.amount)! 
        buyButton.setTitle(priceTag, for: .normal)
        cardForm = TPDForm.setup(withContainer: cardView)
        cardForm.setErrorColor(ColorPalette.alertRed)
        cardForm.setOkColor(.black)
        cardForm.setNormalColor(.gray)
        cardForm.setIsUsedCcv(true)
        cardForm.onFormUpdated {[weak self] (status) in
            OperationQueue.main.addOperation {
                self?.updateViewsForFormStatus(status)
            }
        }
        cardholderFieldView.title = Localized.shippingInfoTerms.cardholder
        emailFieldView.title = Localized.titles.email
        phoneFieldView.title = Localized.shippingInfoTerms.phoneNumberShort
        countryFieldView.title = Localized.shippingInfoTerms.country
        tapToEndEditingRequestTracker = ReferenceTracker()
        endEditingTapRequestHandle = tapToEndEditingRequestTracker.isEmptyDidChangeObservers.add {[weak self] (_) in
            self?.updateEndEditingTap()
        }
        updateEndEditingTap()
        prepareFields()
        updateFieldsForCountry()
    }
    
    private func prepareFields() {
        let delegate = CountryInputFieldDelegate()
        delegate.showCountryPickerAction = {[weak self] in
            self?.performSegue(withIdentifier: SegueID.showCountryPicker, sender: nil)
        }
        countryFieldView.inputFieldDelegate = delegate
        let cardholderDelegate = makeFieldDelegate()
        cardholderDelegate.nextInputView = emailFieldView
        cardholderDelegate.didEndEditing = {[weak self] field in
            self?.draft.name = field.text ?? ""
        }
        cardholderFieldView.inputFieldDelegate = cardholderDelegate
        cardholderFieldView.inputDidChange = {[weak self] field in
            self?.draft.name = field.text ?? ""
        }
        let emailDelegate = makeFieldDelegate()
        emailDelegate.nextInputView = phoneFieldView
        emailDelegate.inputValidator = InputValidators.emailCharacters
        emailDelegate.didEndEditing = {[weak self] field in
            self?.draft.email = field.text ?? ""
        }
        emailFieldView.inputFieldDelegate = emailDelegate
        emailFieldView.inputDidChange = {[weak self] field in
            self?.draft.email = field.text ?? ""
        }
        let phoneDelegate = makeFieldDelegate()
        phoneDelegate.inputValidator = InputValidators.phoneNumberCharacter
        phoneDelegate.didEndEditing = {[weak self] field in
            self?.draft.phoneNumber = field.text ?? ""
        }
        phoneFieldView.inputFieldDelegate = phoneDelegate
        phoneFieldView.inputDidChange = {[weak self] field in
            self?.draft.phoneNumber = field.text ?? ""
        }
    }
    
    private func makeFieldDelegate() -> CardInfoInputFieldDelegate {
        let delegate = CardInfoInputFieldDelegate()
        delegate.tapToEndEditingRequestTracker = tapToEndEditingRequestTracker
        return delegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let observer = KeyboardAppearanceObserver()
        observer.keyboardWillChange = {[weak self] change in
            self?.handleKeyboardChange(change)
        }
        keyboardObserver = observer
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardObserver = nil
    }
    
    private func updateViewsForFormStatus(_ status: TPDStatus) {
        lastStatus = status
        updateBuyButton()
    }
    
    func handleKeyboardChange(_ change: KeyboardChangeInfo) {
        let isAppearing = view.bounds.intersects(change.endRect)
        additionalSafeAreaInsets.bottom = isAppearing ? change.endRect.height : 0
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buy(_ sender: UIButton) {
        guard buyRubyOperation == nil else { return }
        let loading = FullscreenLoadingViewController.fromDefaultStoryboard()
        present(loading, animated: false, completion: nil)
        let op = BuyRubyFlowOperation(form: cardForm, plan: plan, cardholderInfo: draft, userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.dismisLoading(completion: {
                    self?.didBuyRuby()
                })
            }
        }
        buyRubyOperation = op
        op.start()
    }

    func dismisLoading(completion: @escaping (()->())) {
        if presentedViewController != nil {
            dismiss(animated: false, completion: completion)
        } else {
            completion()
        }
    }

    @IBAction func tapToEndEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
    
    private func didBuyRuby() {
        let op = buyRubyOperation!
        buyRubyOperation = nil
        if op.success == true {
            successHandler?()
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? PickerTableViewController {
            vc.title = Localized.shippingInfoTerms.country
            vc.options = draft.phoneNumberBuilder.countries.map{CountryCodePickerItem(countryCode: $0)}
            vc.didSelectItem = {[weak self] item in
                self?.handelSelectedCountry(from: item as! CountryCodePickerItem)
            }
            if let country = draft.country {
                vc.selection = CountryCodePickerItem(countryCode: country)
            }
        }
    }
}


extension CardInputViewController {
    struct SegueID {
        static let showCountryPicker = "showCountryPicker"
    }
}

private extension CardInputViewController {
    func updateBuyButton() {
        buyButton.isEnabled = buyRubyOperation == nil && lastStatus?.isCanGetPrime() == true && !draft.hasEmptyRequiredField
    }
    
    func handelSelectedCountry(from item: CountryCodePickerItem) {
        draft.country = item.countryCode
        updateFieldsForCountry()
    }

    func updateFieldsForCountry() {
        if let country = draft.country {
            countryFieldView.field.text = country.cellPhoneContryCode
        } else {
            countryFieldView.field.text = nil
        }
    }

    func updateEndEditingTap() {
        endEditingTap.isEnabled = !tapToEndEditingRequestTracker.isEmpty
    }
    
    func showAlert(with error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

class CardInfoInputView: UIStackView {
    var inputDidChange: ((UITextField)->())?
    var title: String? {
        set {
            titleLabel.text = newValue
        }
        get {
            return titleLabel.text
        }
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var field: UITextField!
    var inputFieldDelegate: UITextFieldDelegate? {
        didSet {
            field.delegate = inputFieldDelegate
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        field.addTarget(self, action: #selector(notifyInputChange(_:)), for: .editingChanged)
    }

    @IBAction func notifyInputChange(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        inputDidChange?(sender)
    }
}

class CardInfoInputFieldDelegate: NSObject, UITextFieldDelegate {
    var nextInputView: CardInfoInputView?
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
        if let next = nextInputView {
            next.field.becomeFirstResponder()
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

class CardCountryInputFieldDelegate: CardInfoInputFieldDelegate {
    var showCountryPickerAction: (()->())?
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showCountryPickerAction?()
        return false
    }
    
    override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}


class CardholderInfoDraft {
    let updateObservers = MulticastCallbackNode<()->()>()
    var name: String = "" {
        didSet {
            if oldValue != name {
                notifyChange()
            }
        }
    }
    var email: String = "" {
        didSet {
            if oldValue != email {
                notifyChange()
            }
        }
    }
    var country: CountryCode? {
        didSet {
            if oldValue != country {
                notifyChange()
            }
        }
    }
    var phoneNumber: String {
        set {
            phoneNumberBuilder.nationalNumber = newValue
            notifyChange()
        }
        get {
            return phoneNumberBuilder.nationalNumber
        }
    }
    private(set) var phoneNumberBuilder: PhoneNumberBuilder!
    private let phoneNumberValidator: PhoneNumberValidator
    private let emailValidator: TextInputValidator
    private let nameValidator: TextInputValidator

    init() {
        let builder = PhoneNumberBuilder(countryCode: nil)
        phoneNumberBuilder = builder
        country = builder.countryCode
        let phoneValidator = PhoneNumberValidator()
        phoneValidator.phoneNumberBuilder = builder
        phoneNumberValidator = phoneValidator
        emailValidator = InputValidators.email
        nameValidator = NonEmptyInputValidator()
    }
    
    func validate() throws {
        if country == nil {
            throw GenericAppError("Please select a country")
        }
        try nameValidator.validate(name)
        try emailValidator.validate(email)
        try phoneNumberValidator.validate(phoneNumber)
    }

    var hasEmptyRequiredField: Bool {
        return [name, email, phoneNumber].first{$0.isEmpty} != nil
    }

    private func notifyChange() {
        updateObservers.invokeEach{$0()}
    }

}
