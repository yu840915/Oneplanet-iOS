//
//  ShippingInfoDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/15.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

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
            .email: ValidatorPair(intermediate: InputValidators.emailCharacters, final: InputValidators.email),
            .firstName: namePair,
            .lastName: namePair,
            .city: namePair,
            .country: namePair,
            .region: namePair,
            .postalCode: ValidatorPair(intermediate: InputValidators.digits, final: InputValidators.digits),
            .address1: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: InputValidators.romanAddress),
            .address2: ValidatorPair(intermediate: OrValidator([InputValidators.romanAddress, EmptyInputValidator()]), final: OrValidator([InputValidators.romanAddress, EmptyInputValidator()])),
            .phoneNumber: ValidatorPair(intermediate: InputValidators.phoneNumberCharacter, final: PhoneNumberValidator())
        ]
        return result
    }()
    
    init() {
        let builder = PhoneNumberBuilder(countryCode: nil)
        phoneNumberBuilder = builder
        country = builder.countryCode
        let validator = validatorPairs[.phoneNumber]!.final as! PhoneNumberValidator
        validator.phoneNumberBuilder = builder
    }
    
    convenience init(_ shipping: ShippingAddress) {
        self.init()
        email = shipping.email ?? ""
        firstName = shipping.firstName ?? ""
        lastName = shipping.lastName ?? ""
        address1 = shipping.addressLine1 ?? ""
        address2 = shipping.addressLine2 ?? ""
        if let countryCode = shipping.country {
            country = phoneNumberBuilder.countries.first{$0.isoCountryCode.lowercased() == countryCode.lowercased()}
        }
        region = shipping.region ?? ""
        city = shipping.city ?? ""
        postalCode = shipping.postalCode ?? ""
        phoneNumber = shipping.phone ?? ""
    }
    
    private func notifyChange() {
        updateObservers.invokeEach{$0()}
    }
    
    func validate() throws {
        let checkOrder: [Field] = [.email, .firstName, .lastName, .address1, .address2, .city, .region, .postalCode, .country, .phoneNumber]
        try checkOrder.forEach { field in
            try validate(field, with: validatorPairs[field]!.final)
        }
    }
    
    private func validate(_ field: Field, with validator: TextInputValidator) throws {
        do {
            try validator.validate(self[field])
        } catch let error as NSError {
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
    let inputError: NSError
    init(field: ShippingInfoDraft.Field, inputError: NSError) {
        self.field = field
        self.inputError = inputError
        super.init(domain: inputError.domain, code: inputError.code, userInfo: inputError.userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PhoneNumberValidator: TextInputValidator {
    var phoneNumberBuilder: PhoneNumberBuilder!
    
    override func validate(_ input: String) throws {
        do {
            _ = try phoneNumberBuilder.phoneNumberKit.parse(phoneNumberBuilder.countryCode.cellPhoneContryCode + input)
        } catch let error {
            logger.debug("Input error: \(error)")
            throw InputError(localizedDescription: Localized.errors.invalidPhoneNumber)
        }
    }
}

class SubmitShippingInfoOperation: AlamofireAPIAccessOperation {
    typealias CodingKeys = ShippingAddress.CodingKeys
    let draft: ShippingInfoDraft
    let session: UserSession
    init(draft: ShippingInfoDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try draft.validate()
        var params: Parameters = [
            CodingKeys.email.rawValue: draft.email,
            CodingKeys.firstName.rawValue: draft.firstName,
            CodingKeys.lastName.rawValue: draft.lastName,
            CodingKeys.addressLine1.rawValue: draft.address1,
            CodingKeys.addressLine2.rawValue: draft.address2,
            CodingKeys.city.rawValue: draft.city,
            CodingKeys.region.rawValue: draft.region,
            CodingKeys.phone.rawValue: draft.phoneNumber,
            CodingKeys.postalCode.rawValue: draft.postalCode
        ]
        if let country = draft.country {
            params[CodingKeys.country.rawValue] = country.isoCountryCode
        }
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("me/shipping"), method: .put, parameters: params, encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}

class GetShippingAddressOperation: AlamofireAPIAccessOperation {
    let session: UserSession
    private(set) var shippingAddress: ShippingAddress?
    
    init(session: UserSession) {
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("me/shipping")))
    }
    
    override func processData(with data: Data) throws {
        guard !data.isEmpty else { return }
        shippingAddress = try? JSONDecoder.default.decode(ShippingAddress.self, from: data)
    }
    
    override func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        if response.statusCode == 404 { return }
        try super.handleHTTPResponse(response)
    }
}

class ShippingAddress: Decodable {
    let email: String?
    let firstName: String?
    let lastName: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let region: String?
    let postalCode: String?
    let country: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case addressLine1 = "address_line1"
        case addressLine2 = "address_line2"
        case city
        case region
        case postalCode = "postal_code"
        case country
        case phone = "phone_number"
    }
}
