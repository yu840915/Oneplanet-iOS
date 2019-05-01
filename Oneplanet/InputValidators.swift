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
    static let alphanumerics = AlphanumericInputValidator()
    static let password = AndValidator([InputLengthValidator(min: 6, max: 12), alphanumerics])
    static let intermediatePassword = AndValidator([InputLengthValidator(max: 12), alphanumerics])
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

class InputLengthValidator: TextInputValidator {
    let min: Int?
    let max: Int?
    init(min: Int, max: Int) {
        assert(max >= min)
        assert(min >= 0)
        self.min = min
        self.max = max
    }
    
    init(min: Int) {
        assert(min >= 0)
        self.min = min
        max = nil
    }
    
    init(max: Int) {
        assert(max >= 0)
        self.max = max
        min = nil
    }
    
    override func validate(_ input: String) throws {
        if let min = self.min {
            if input.count < min {
                throw InputError(localizedDescription: formattedErrorMessage)
            }
        }
        if let max = self.max {
            if input.count > max {
                throw InputError(localizedDescription: formattedErrorMessage)
            }
        }
    }
    
    private var formattedErrorMessage: String {
        if let min = self.min, let max = self.max {
            return "There should be \(min) to \(max) characters"
        }
        if let min = self.min {
            return "There should be at least \(min) characters"
        }
        if let max = self.max {
            return "There should be at most \(max) characters"
        }
        return ""
    }
}
