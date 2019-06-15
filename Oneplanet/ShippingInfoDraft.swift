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
    var country: String = "" {
        didSet {
            if oldValue != country {
                notifyChange()
            }
        }
    }
    var phoneNumber: String = "" {
        didSet {
            if oldValue != phoneNumber {
                notifyChange()
            }
        }
    }
    
    func validatorPair(for field: Field) -> ValidatorPair {
        return validatorPairs[field]!
    }
    
    private var validatorPairs: [Field: ValidatorPair] = {
        let result: [Field: ValidatorPair] = [
            .email: ValidatorPair(intermediate: InputValidators.emailCharacters, final: InputValidators.email, field: .email),
            .firstName: ValidatorPair(intermediate: OrValidator([InputValidators.romanName, EmptyInputValidator()]), final: InputValidators.romanName, field: .firstName),
            .lastName: ValidatorPair(intermediate: OrValidator([InputValidators.romanName, EmptyInputValidator()]), final: InputValidators.romanName, field: .lastName),
            .city: ValidatorPair(intermediate: OrValidator([InputValidators.romanName, EmptyInputValidator()]), final: InputValidators.romanName, field: .city),
            .country: ValidatorPair(intermediate: OrValidator([InputValidators.romanName, EmptyInputValidator()]), final: InputValidators.romanName, field: .country),
            .region: ValidatorPair(intermediate: OrValidator([InputValidators.romanName, EmptyInputValidator()]), final: InputValidators.romanName, field: .region),
            .postalCode: ValidatorPair(intermediate: InputValidators.digits, final: InputValidators.digits, field: .postalCode),
            .address1: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: InputValidators.romanAddress, field: .address1),
            .address2: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), field: .address2)
            //phone
        ]
        return result
    }()
    
    private func notifyChange() {
        updateObservers.invokeEach{$0()}
    }
    
    func validate() throws {
        try validatorPairs.forEach { field, pair in
            try validate(field, with: pair.final)
        }
    }
    
    private func validate(_ field: Field, with validator: TextInputValidator) throws {
        let input: String
        switch field {
        case .email:
            input = email
        case .address1:
            input = address1
        case .address2:
            input = address2
        case .city:
            input = city
        case .country:
            input = country
        case .firstName:
            input = firstName
        case .lastName:
            input = lastName
        case .phoneNumber:
            input = phoneNumber
        case .region:
            input = region
        case .postalCode:
            input = postalCode
        }
        try validator.validate(input)
    }
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch _ {
            return false
        }
    }

}

extension ShippingInfoDraft {
    class ValidatorPair {
        let intermediate: TextInputValidator
        let final: TextInputValidator
        init(intermediate: TextInputValidator, final: TextInputValidator, field: Field) {
            self.intermediate = intermediate
            self.final = InputValidatorWrapper(validator: final, field: field)
        }
    }
    
    class InputValidatorWrapper: TextInputValidator {
        let field: Field
        let validator: TextInputValidator
        init(validator: TextInputValidator, field: Field) {
            self.field = field
            self.validator = validator
        }
        
        override func validate(_ input: String) throws {
            do {
                try validator.validate(input)
            } catch let error as InputError {
                throw ShippingInfoInputError(field: field, inputError: error)
            }
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
