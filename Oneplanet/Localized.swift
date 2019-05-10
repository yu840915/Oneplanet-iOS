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
    static let phrases = LocalizedPhrase()
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
    var ok: String {
        return NSLocalizedString("tl_ok", comment: "")
    }
    var skip: String {
        return NSLocalizedString("tl_skip", comment: "")
    }
    var allPhotos: String {
        return NSLocalizedString("tl_all_photos", comment: "")
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
    var exit: String {
        return NSLocalizedString("tl_exit", comment: "")
    }
    var back: String {
        return NSLocalizedString("tl_back", comment: "")
    }
}

class LocalizedPlaceholder {//pl_
    fileprivate init() {}
    var email: String {
        return NSLocalizedString("pl_email", comment: "")
    }
    var nickname: String {
        return NSLocalizedString("pl_nickname", comment: "")
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
    var emailVerificationInstruction: String {
        return NSLocalizedString("msg_email_verification_instruction", comment: "")
    }
    var addAvatarPrompt: String {
        return NSLocalizedString("msg_add_avatar_prompt", comment: "")
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
    var emailLogin: String {
        return NSLocalizedString("ph_email_login", comment: "")
    }
    var resendEmail: String {
        return NSLocalizedString("ph_resend_email", comment: "")
    }
    var newUserGreeting: String {
        return NSLocalizedString("ph_newuser_greeting", comment: "")
    }
    var addAvatar: String {
        return NSLocalizedString("ph_add_avatar", comment: "")
    }
    var avatarAdded: String {
        return NSLocalizedString("ph_avatar_added", comment: "")
    }
    var changeAvatar: String {
        return NSLocalizedString("ph_change_avatar", comment: "")
    }
    var takePhoto: String {
        return NSLocalizedString("ph_take_photo", comment: "")
    }
    var fromLibrary: String {
        return NSLocalizedString("ph_from_library", comment: "")
    }
    var openSettings: String {
        return NSLocalizedString("ph_open_settings", comment: "")
    }
    var removeAvatar: String {
        return NSLocalizedString("ph_remove_avatar", comment: "")
    }
    var tryAgain: String {
        return NSLocalizedString("ph_try_again", comment: "")
    }
    var nicknameRule: String {
        return NSLocalizedString("ph_nickname_rule", comment: "")
    }
}

class LocalizedErrorsTitles {//errtl_
    fileprivate init() {}
    var cannotCapturePhoto: String {
        return NSLocalizedString("errtl_cannot_capture_photo", comment: "")
    }
    var cannotPickAvatar: String {
        return NSLocalizedString("errtl_cannot_pick_avatar", comment: "")
    }
}

class LocalizedErrors {//err_
    fileprivate init() {}
    var noCameraAccess: String {
        return NSLocalizedString("err_no_camera_access", comment: "")
    }
    var noLibraryAccess: String {
        return NSLocalizedString("err_no_library_access", comment: "")
    }
    var invalidEmail: String {
        return NSLocalizedString("err_invalid_email", comment: "")
    }
    var nonAlphanumericalCharacter: String {
        return NSLocalizedString("err_non_alphanumerics", comment: "")
    }
    var accountDoesnotExist: String {
        return NSLocalizedString("err_account_not_exist", comment: "")
    }
    var invalidNickname: String {
        return NSLocalizedString("err_invalid_nickname", comment: "")
    }
}
