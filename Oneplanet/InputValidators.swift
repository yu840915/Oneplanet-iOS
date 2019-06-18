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
    static let emailCharacters = EmailCharacterValidator()
    static let alphanumerics = AlphanumericInputValidator()
    static let digits = DigitInputValidator()
    static let romanName = RomanNameValidator()
    static let password = AndValidator([InputLengthValidator(min: 6, max: 12), alphanumerics])
    static let romanAddress = RomanAddressValidator()
    static let intermediatePassword = AndValidator([InputLengthValidator(max: 12), alphanumerics])
    static let phoneNumberCharacter = PhoneNumberCharacterValidator()
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

class EmailCharacterValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[A-Z0-9a-z._%+@-]+"
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

class NonEmptyInputValidator: TextInputValidator {
    override func validate(_ input: String) throws {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw InputError(localizedDescription: "No contents")
        }
    }
}

class NicknameInputValidator: TextInputValidator {
    override func validate(_ input: String) throws {
        var components = input.components(separatedBy: .whitespaces)
        if components.last == "" {
            components.removeLast()
        }
        try components.forEach { (str) in
            if str.isEmpty || !CharacterSet(charactersIn: str).subtracting(.letters).subtracting(.decimalDigits).isEmpty {
                throw  InputError(localizedDescription: Localized.errors.invalidNickname)
            }
        }
    }
}

class EmptyInputValidator: TextInputValidator {
    override func validate(_ input: String) throws {
        if !input.isEmpty {
            throw InputError(localizedDescription: "Non-zero input")
        }
    }
}

class DigitInputValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[0-9]+"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.nonDigitInput)
    }
}

class RomanNameValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[A-Za-zÀ-ÖØ-öø-ÿ ,.-]+"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.nonDigitInput)
    }
}

class RomanAddressValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 \\(\\),.-]+"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.nonDigitInput)
    }
}

class PhoneNumberCharacterValidator: TextInputValidator {
    private let predicate: NSPredicate
    
    override init() {
        let regex = "[0-9\\+*#]+"
        predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if predicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.nonDigitInput)
    }

}
