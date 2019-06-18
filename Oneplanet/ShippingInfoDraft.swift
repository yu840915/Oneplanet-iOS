//
//  ShippingInfoDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class ShippingInfoDraft {
    let updateObservers = MulticastCallbackNode<()->()>()
    var email: String = "" {
        didSet {
            if oldValue != email {
                notifyChange()
            }
        }
    }
    var firstName: String = "" {
        didSet {
            if oldValue != firstName {
                notifyChange()
            }
        }
    }
    var lastName: String = "" {
        didSet {
            if oldValue != lastName {
                notifyChange()
            }
        }
    }
    var address1: String = "" {
        didSet {
            if oldValue != address1 {
                notifyChange()
            }
        }
    }
    var address2: String = "" {
        didSet {
            if oldValue != address2 {
                notifyChange()
            }
        }
    }
    var city: String = "" {
        didSet {
            if oldValue != city {
                notifyChange()
            }
        }
    }
    var region: String = "" {
        didSet {
            if oldValue != region {
                notifyChange()
            }
        }
    }
    var postalCode: String = "" {
        didSet {
            if oldValue != postalCode {
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
    
    func validatorPair(for field: Field) -> ValidatorPair {
        return validatorPairs[field]!
    }
    
    private var validatorPairs: [Field: ValidatorPair] = {
        let namePair = ValidatorPair(intermediate: InputValidators.romanName, final: InputValidators.romanName)
        let result: [Field: ValidatorPair] = [
            .email: namePair,
            .firstName: namePair,
            .lastName: namePair,
            .city: namePair,
            .country: namePair,
            .region: namePair,
            .postalCode: ValidatorPair(intermediate: InputValidators.digits, final: InputValidators.digits),
            .address1: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: InputValidators.romanAddress),
            .address2: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: OrValidator([InputValidators.romanAddress, EmptyInputValidator()])),
            .phoneNumber: ValidatorPair(intermediate: InputValidators.digits, final: InputValidators.digits)
        ]
        return result
    }()
    
    init() {
        let builder = PhoneNumberBuilder(countryCode: nil)
        phoneNumberBuilder = builder
        country = builder.countryCode
    }
    
    private func notifyChange() {
        updateObservers.invokeEach{$0()}
    }
    
    func validate() throws {
        try validatorPairs.forEach { field, pair in
            try validate(field, with: pair.final)
        }
    }
    
    private func validate(_ field: Field, with validator: TextInputValidator) throws {
        do {
            try validator.validate(self[field])
        } catch let error as InputError {
            throw ShippingInfoInputError(field: field, inputError: error)
        }
    }
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch _ {
            return false
        }
    }
    
    var hasEmptyRequiredField: Bool {
        return requiredFields.map{self[$0]}.first{$0.isEmpty} != nil
    }
    
    let requiredFields: [Field] = [.email, .firstName, .lastName, .address1, .city, .region, .postalCode, .phoneNumber, .country]
    
    subscript(idx: Field) -> String {
        get {
            switch idx {
            case .email: return email
            case .address1: return address1
            case .address2: return address2
            case .city: return city
            case .country: return country?.displayName() ?? ""
            case .firstName: return firstName
            case .lastName: return lastName
            case .phoneNumber: return phoneNumber
            case .region: return region
            case .postalCode: return postalCode
            }
        }
        set {
            switch idx {
            case .email: email = newValue
            case .address1: address1 = newValue
            case .address2: address2 = newValue
            case .city: city = newValue
            case .country: break
            case .firstName: firstName = newValue
            case .lastName: lastName = newValue
            case .phoneNumber: phoneNumber = newValue
            case .region: region = newValue
            case .postalCode: postalCode = newValue
            }
        }
    }
    
    
}

extension ShippingInfoDraft {
    class ValidatorPair {
        let intermediate: TextInputValidator
        let final: TextInputValidator
        init(intermediate: TextInputValidator, final: TextInputValidator) {
            self.intermediate = intermediate
            self.final = final
        }
    }

    enum Field: String {
        case email, firstName, lastName, address1, address2, city, region, postalCode, country, phoneNumber
    }
}

class ShippingInfoInputError: NSError {
    let field: ShippingInfoDraft.Field
    let inputError: InputError
    init(field: ShippingInfoDraft.Field, inputError: InputError) {
        self.field = field
        self.inputError = inputError
        super.init(domain: inputError.domain, code: inputError.code, userInfo: inputError.userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
