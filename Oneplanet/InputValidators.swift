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
}

class EmailInputValidator: TextInputValidator {
    private let emailPredicate: NSPredicate
    
    override init() {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        emailPredicate = NSPredicate(format:"SELF MATCHES %@", regex)
        super.init()
    }
    
    override func validate(_ input: String) throws {
        if emailPredicate.evaluate(with: input) {
            return
        }
        throw InputError(localizedDescription: Localized.errors.invalidEmail)
    }
}
