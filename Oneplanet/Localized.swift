//
//  Localized.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class Localized {
    static let titles = LocalizedTitles()
    static let warnings = LocalizedWarnings()
    static let errors = LocalizedErrors()
    static let errorTitles = LocalizedErrorsTitles()
    static let messages = LocalizedMessages()
    static let messageFormats = LocalizedMessageFormats()
    static let phrase = LocalizedPhrase()
    static let activity = LocalizedActivityMessages()
    static let placeholder = LocalizedPlaceholder()
}

class LocalizedTitles {//tl_
    fileprivate init() {}
    var cancel: String {
        return NSLocalizedString("tl_cancel", comment: "")
    }
    var dismiss: String {
        return NSLocalizedString("tl_dismiss", comment: "")
    }
    var done: String {
        return NSLocalizedString("tl_done", comment: "")
    }
    var skip: String {
        return NSLocalizedString("tl_skip", comment: "")
    }
    var allPhotos: String {
        return NSLocalizedString("tl_all_photos", comment: "")
    }
    var signUp: String {
        return NSLocalizedString("tl_signup", comment: "")
    }
    var logIn: String {
        return NSLocalizedString("tl_login", comment: "")
    }
    var title: String {
        return NSLocalizedString("tl_title", comment: "")
    }
    var tos: String {
        return NSLocalizedString("tl_tos", comment: "")
    }
    var pp: String {
        return NSLocalizedString("tl_pp", comment: "")
    }
    var next: String {
        return NSLocalizedString("tl_next", comment: "")
    }
}

class LocalizedPlaceholder {//pl_
    fileprivate init() {}
    var email: String {
        return NSLocalizedString("pl_email", comment: "")
    }
    var password: String {
        return NSLocalizedString("pl_password", comment: "")
    }
}

class LocalizedActivityMessages {//act_
    fileprivate init() {}
}

class LocalizedWarnings {//warn_
    fileprivate init() {}
}

class LocalizedMessages {//msg_
    fileprivate init() {}
    var loginPrompt: String {
        return NSLocalizedString("msg_login_prompt", comment: "")
    }
    var emailVerificationInstruction: String {
        return NSLocalizedString("msg_email_verification_instruction", comment: "")
    }
    var passwordRules: String {
        return NSLocalizedString("msg_password_rules", comment: "")
    }
}

class LocalizedMessageFormats {//msgf_
    fileprivate init() {}
    var acceptTOS: String {
        return NSLocalizedString("msgf_accept_tos", comment: "")
    }
    var resendVerificationEmail: String {
        return NSLocalizedString("msgf_resend_verification_email", comment: "")
    }
}
class LocalizedPhrase { //ph_
    fileprivate init() {}
    var geustLogin: String {
        return NSLocalizedString("ph_guest_login", comment: "")
    }
    var or: String {
        return NSLocalizedString("ph_or", comment: "")
    }
    var socialLogin: String {
        return NSLocalizedString("ph_social_login", comment: "")
    }
    var emailSignUp: String {
        return NSLocalizedString("ph_email_signup", comment: "")
    }
    var resendEmail: String {
        return NSLocalizedString("ph_resend_email", comment: "")
    }
    var forgetPassword: String {
        return NSLocalizedString("ph_forget_password", comment: "")
    }
}

class LocalizedErrorsTitles {//errtl_
    fileprivate init() {}
    var cannotCapturePhoto: String {
        return NSLocalizedString("errtl_cannot_capture_photo", comment: "")
    }

}

class LocalizedErrors {//err_
    fileprivate init() {}
    var noCameraAccess: String {
        return NSLocalizedString("err_no_camera_access", comment: "")
    }
}
