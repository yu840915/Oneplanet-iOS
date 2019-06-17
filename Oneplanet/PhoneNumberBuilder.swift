//
//  PhoneNumberBuilder.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import PhoneNumberKit

class PhoneNumberBuilder {
    var nationalNumber: String = ""
    var phoneNumberKit = PhoneNumberKit()
    let locale = Locale(identifier: "en-US")
    var countryCode: CountryCode!
    var countries: [CountryCode] {
        return phoneNumberKit.allCountries().compactMap{CountryCode(isoCountryCode: $0, locale: locale, phoneNumberKit: phoneNumberKit)}
    }
    
    init(countryCode: CountryCode?) {
        self.countryCode = countryCode ?? CountryCode(isoCountryCode: PhoneNumberKit.defaultRegionCode(), locale: locale, phoneNumberKit: phoneNumberKit)!
    }
    
    var isValid: Bool {
        guard let number = parse() else {
            return false
        }
        return true
    }
    
    private func parse() -> PhoneNumber? {
        do {
            return try phoneNumberKit.parse(nationalNumber, withRegion: countryCode.isoCountryCode, ignoreType: true)
        } catch let error as NSError {
            debugPrint(error)
            return nil
        }
    }
    
//    private func validate(_ number: PhoneNumber) -> Bool {
//        
//        return phoneNumberKit.isValidNumber(number)
//    }
//    
//    func asFormattedString() -> String? {
//        guard let number = parse(), validate(number), let national = number.nationalNumber else {
//            return nil
//        }
//        return countryCode.cellPhoneContryCode + "\(national)"
//    }
}

class CountryCode {
    
    let locale: Locale
    let phoneNumberKit: PhoneNumberKit
    init?(isoCountryCode: String, locale: Locale, phoneNumberKit: PhoneNumberKit) {
        guard let cellPhoneCode = phoneNumberKit.countryCode(for: isoCountryCode),
            cellPhoneCode != 0 else {
                return nil
        }
        self.locale = locale
        self.phoneNumberKit = phoneNumberKit
        self.isoCountryCode = isoCountryCode.uppercased()
        cellPhoneContryCodeNumber = cellPhoneCode
    }
    
    let cellPhoneContryCodeNumber: UInt64
    var cellPhoneContryCode: String {
        return "+\(cellPhoneContryCodeNumber)"
    }
    let isoCountryCode: String
    
    func displayName() -> String? {
        return locale.localizedString(forRegionCode: isoCountryCode)
    }
    
    func matches(_ text: String) -> Bool {
        let allValues = cellPhoneContryCode + isoCountryCode + (displayName() ?? "")
        return allValues.lowercased().contains(text.lowercased())
    }
}

extension CountryCode: Equatable {
    
    public static func ==(lhs: CountryCode, rhs: CountryCode) -> Bool {
        return lhs.isoCountryCode == rhs.isoCountryCode
    }
    
}
