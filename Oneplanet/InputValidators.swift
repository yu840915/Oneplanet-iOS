//
//  InputValidators.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class InputValidators {
    static let email = EmailInputValidator()
    static let password = TextInputValidator()
}

class EmailInputValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.invalidEmail)
    }
}

class AlphanumericInputValidator: TextInputValidator {
    private let predicate: NSPredicate

    override init() {
        let regex = "[A-Z0-9a-z]+"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.nonAlphanumericalCharacter)
    }
}

class InputLengthValidator {
    
}
