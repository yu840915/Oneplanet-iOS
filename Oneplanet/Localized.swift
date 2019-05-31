//
//  Localized.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class Localized {
    static let acceptLanguageHeader: [String: String] = [acceptLanguageKey: languageCode]
    static let acceptLanguageKey = "Accept-Language"
    static let languageCode: String = NSLocalizedString("iso_code", comment: "")
    static let titles = LocalizedTitles()
    static let warnings = LocalizedWarnings()
    static let warningTitles = LocalizedWarningTitles()
    static let errors = LocalizedErrors()
    static let errorTitles = LocalizedErrorsTitles()
    static let messages = LocalizedMessages()
    static let messageFormats = LocalizedMessageFormats()
    static let phrases = LocalizedPhrase()
    static let activity = LocalizedActivityMessages()
    static let placeholder = LocalizedPlaceholder()
    static let emptyMessages = EmptyMessages()
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
    var logOut: String {
        return NSLocalizedString("tl_log_out", comment: "")
    }
    var title: String {
        return NSLocalizedString("tl_title", comment: "")
    }
    var tos: String {
        return NSLocalizedString("tl_tos", comment: "")
    }
    var biddingTerms: String {
        return NSLocalizedString("tl_bidding_terms", comment: "")
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
    var more: String {
        return NSLocalizedString("tl_more", comment: "")
    }
    var account: String {
        return NSLocalizedString("tl_account", comment: "")
    }
    var me: String {
        return "MY"
//        return NSLocalizedString("tl_me", comment: "")
    }
    var mailSent: String {
        return NSLocalizedString("tl_mail_sent", comment: "")
    }
    var nickname: String {
        return Localized.placeholder.nickname
    }
    var userId: String {
        return NSLocalizedString("tl_user_id", comment: "")
    }
    var email: String {
        return NSLocalizedString("tl_email", comment: "")
    }
    var gender: String {
        return NSLocalizedString("tl_gender", comment: "")
    }
    var male: String {
        return NSLocalizedString("tl_male", comment: "")
    }
    var female: String {
        return NSLocalizedString("tl_female", comment: "")
    }
    var privateInformation: String {
        return NSLocalizedString("tl_private_info", comment: "")
    }
    var facebook: String {
        return "Facebook"
    }
    var twitter: String {
        return "Twitter"
    }
    var wechat: String {
        return "WeChat"
    }
    var go: String {
        return NSLocalizedString("tl_go", comment: "")
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
    var logout: String {
        return NSLocalizedString("warn_logout", comment: "")
    }
    var characterSelection: String {
        return NSLocalizedString("warn_character_selection", comment: "")
    }
}

class LocalizedWarningTitles {//warntl_
    var characterSelection: String {
        return NSLocalizedString("warntl_character_selection", comment: "")
    }
}

class LocalizedMessages {//msg_
    fileprivate init() {}
    var emailVerificationInstruction: String {
        return NSLocalizedString("msg_email_verification_instruction", comment: "")
    }
    var addAvatarPrompt: String {
        return NSLocalizedString("msg_add_avatar_prompt", comment: "")
    }
    var openMailAppPrompt: String {
        return NSLocalizedString("msg_open_mail_app_prompt", comment: "")
    }
    var mailResent: String {
        return NSLocalizedString("msg_mail_resent", comment: "")
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
    var version: String {
        return "Oneplanet v%@"
    }
    var didCopyMyId: String {
        return NSLocalizedString("msgf_did_copy_my_id", comment: "")
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
    var copyID: String {
        return NSLocalizedString("ph_copy_id", comment: "")
    }
    var follow: String {
        return NSLocalizedString("ph_follow", comment: "")
    }
    var following: String {
        return NSLocalizedString("ph_following", comment: "")
    }
    var chooseRole: String {
        return NSLocalizedString("ph_choose_role", comment: "")
    }
    var chooseColor: String {
        return NSLocalizedString("ph_choose_color", comment: "")
    }
    var editProfile: String {
        return NSLocalizedString("ph_edit_profile", comment: "")
    }
    var blockList: String {
        return NSLocalizedString("ph_block_list", comment: "")
    }
    var privacyAndSecurity: String {
        return NSLocalizedString("ph_privacy_and_security", comment: "")
    }
    var notSpecified: String {
        return NSLocalizedString("ph_not_specified", comment: "")
    }
}

class EmptyMessages {//no_
    var posts: String {
        return NSLocalizedString("no_posts", comment: "")
    }
    var promoPopups: String {
        return NSLocalizedString("no_promo_popups", comment: "")
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
