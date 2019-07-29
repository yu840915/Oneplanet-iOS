//
//  Localized.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class Localized {
    static let feature = Feature()
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
    static let gemStonePopUp = GemStonePopUp()
    static let shippingInfoTerms = LocalizedShippingInfoTerms()
    static let phraseFormats = LocalizedPhraseFormats()
    static let reportReasons = LocalizedReportReasons()
    static let symbols = LocalizedSimbols()
    
}

class LocalizedTitles {//tl_
    fileprivate init() {}
    var blueGem: String {
        return NSLocalizedString("tl_blue_gem", comment: "")
    }
    var greenGem: String {
        return NSLocalizedString("tl_green_gem", comment: "")
    }
    var purpleGem: String {
        return NSLocalizedString("tl_purple_gem", comment: "")
    }
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
    var logins: String {
        return NSLocalizedString("tl_logins", comment: "")
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
    var delete: String {
        return NSLocalizedString("tl_delete", comment: "")
    }
    var unlock: String {
        return NSLocalizedString("tl_unlock", comment: "")
    }
    var unlocked: String {
        return NSLocalizedString("tl_unlocked", comment: "")
    }
    var bid: String {
        return NSLocalizedString("tl_bid", comment: "")
    }
    var requiredInput: String {
        return NSLocalizedString("tl_required_input", comment: "")
    }
    var agree: String {
        return NSLocalizedString("tl_agree", comment: "")
    }
    var filter: String {
        return NSLocalizedString("tl_filter", comment: "")
    }
    var bidStateLose: String {
        return NSLocalizedString("tl_bid_state_lost", comment: "")
    }
    var bidStateToShip: String {
        return NSLocalizedString("tl_bid_state_to_ship", comment: "")
    }
    var bidStateShipping: String {
        return NSLocalizedString("tl_bid_state_shipping", comment: "")
    }
    var bidStateDelivered: String {
        return NSLocalizedString("tl_bid_state_delivered", comment: "")
    }
    var report: String {
        return NSLocalizedString("tl_report", comment: "")
    }
    var unblock: String {
        return NSLocalizedString("tl_unblock", comment: "")
    }
    var block: String {
        return NSLocalizedString("tl_block", comment: "")
    }
    var followers: String {
        return NSLocalizedString("tl_followers", comment: "")
    }
    var followings: String {
        return NSLocalizedString("tl_followings", comment: "")
    }
    var content: String {
        return NSLocalizedString("tl_content", comment: "")
    }
    var send: String {
        return NSLocalizedString("tl_send", comment: "")
    }
}

class Feature {//fx_
    var hot: String {
        return NSLocalizedString("fx_hot", comment: "")
    }
    var me: String {
        return ""
//        return NSLocalizedString("fx_my", comment: "")
    }
    var life: String {
        return NSLocalizedString("fx_life", comment: "")
    }
    var bid: String {
        return NSLocalizedString("fx_bid", comment: "")
    }
    var notice: String {
        return NSLocalizedString("fx_notice", comment: "")
    }
    var news: String {
        return NSLocalizedString("fx_news", comment: "")
    }
    var events: String {
        return NSLocalizedString("fx_events", comment: "")
    }
    var alien: String {
        return NSLocalizedString("fx_alien", comment: "")
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
    var reportDescription: String {
        return NSLocalizedString("pl_report_description", comment: "")
    }
}

class LocalizedActivityMessages {//act_
    fileprivate init() {}
    var bidding: String {
        return NSLocalizedString("act_bigging", comment: "")
    }
    var biddingEnded: String {
        return NSLocalizedString("act_bigging_ended", comment: "")
    }
    var countdown: String {
        return NSLocalizedString("act_countdown", comment: "")
    }
}

class LocalizedWarnings {//warn_
    fileprivate init() {}
    var logout: String {
        return NSLocalizedString("warn_logout", comment: "")
    }
    var characterSelection: String {
        return NSLocalizedString("warn_character_selection", comment: "")
    }
    var accountBanned: String {
        return NSLocalizedString("warn_account_banned", comment: "")
    }
}

class LocalizedWarningTitles {//warntl_
    var characterSelection: String {
        return NSLocalizedString("warntl_character_selection", comment: "")
    }
    var accountBanned: String {
        return NSLocalizedString("warntl_account_banned", comment: "")
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
    var joinPrompt: String {
        return NSLocalizedString("msg_join_prompt", comment: "")
    }
    var alienDescription: String {
        return NSLocalizedString("msg_alien_description", comment: "")
    }
    var ongoingBidding: String {
        return NSLocalizedString("msg_ongoing_bidding", comment: "")
    }
    var successfulShippingInfoSubmission: String {
        return NSLocalizedString("msg_successful_shipping_info_submission", comment: "")
    }
    var biddingTermsAcceptence: String {
        return NSLocalizedString("msg_bidding_terms_acceptence", comment: "")
    }
    var unlockSucceeded: String {
        return NSLocalizedString("msg_unlock_succeeded", comment: "")
    }
    var bidSucceeded: String {
        return NSLocalizedString("msg_bid_succeeded", comment: "")
    }
    var lotBeingBid: String {
        return NSLocalizedString("msg_lot_being_bid", comment: "")
    }
    var lotBeingBidDescription: String {
        return NSLocalizedString("msg_lot_being_bid_des", comment: "")
    }
    var lotClosed: String {
        return NSLocalizedString("msg_lot_closed", comment: "")
    }
    var lotClosedDescription: String {
        return NSLocalizedString("msg_lot_closed_des", comment: "")
    }
    var bidPaymentTooLate: String {
        return NSLocalizedString("msg_bid_payment_too_late", comment: "")
    }
    var race1Monologue: String {
        return NSLocalizedString("msg_race1_monologue", comment: "")
    }
    var race2Monologue: String {
        return NSLocalizedString("msg_race2_monologue", comment: "")
    }
    var race3Monologue: String {
        return NSLocalizedString("msg_race3_monologue", comment: "")
    }
    var shippingInfoDescription: String {
        return NSLocalizedString("msg_shipping_info_des", comment: "")
    }
    var reportUserPrompt: String {
        return NSLocalizedString("msg_report_user_prompt", comment: "")
    }
    var reportPostPrompt: String {
        return NSLocalizedString("msg_report_post_prompt", comment: "")
    }
    var reportUserCaption: String {
        return NSLocalizedString("msg_report_user_caption", comment: "")
    }
    var reportPostCaption: String {
        return NSLocalizedString("msg_report_post_caption", comment: "")
    }
    var thankYouForReportingUser: String {
        return NSLocalizedString("msg_thankyou_reporting_user", comment: "")
    }
    var thankYouForReportingPost: String {
        return NSLocalizedString("msg_thankyou_reporting_post", comment: "")
    }
    var unblockDescription: String {
        return NSLocalizedString("msg_unblock_des", comment: "")
    }
    var blockDescription: String {
        return NSLocalizedString("msg_block_des", comment: "")
    }
    var recoverAccountDescription: String {
        return NSLocalizedString("msg_recover_account_des", comment: "")
    }
    var petitionSubmitted: String {
        return NSLocalizedString("msg_petition_submitted", comment: "")
    }
    var unlockOptionPrompt: String {
        return NSLocalizedString("msg_unlock_option_prompt", comment: "")
    }
    var thanksForReportingPost: String {
        return NSLocalizedString("msg_thanks_for_reporting_post", comment: "")
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
    var didCopyId: String {
        return NSLocalizedString("msgf_did_copy_id", comment: "")
    }
    var winnerNotice: String {
        return NSLocalizedString("msgf_winner_notice", comment: "")
    }
    var unlockLot: String {
        return NSLocalizedString("msgf_unlock_lot", comment: "")
    }
    var didUnlockLot: String {
        return NSLocalizedString("msgf_did_unlock_lot", comment: "")
    }
    var unlockWithGemAndIAP: String {
        return NSLocalizedString("msgf_unlock_with_gem_iap", comment: "")
    }
    var unlockWithGem: String {
        return NSLocalizedString("msgf_unlock_with_gem", comment: "")
    }
    var insufficientGem: String {
        return NSLocalizedString("msgf_insufficient_gem", comment: "")
    }
    var bidPrompt: String {
        return NSLocalizedString("msgf_bid_prompt", comment: "")
    }
    var bidWithGemAndIAP: String {
        return NSLocalizedString("msgf_bid_with_gem_iap", comment: "")
    }
    var bidWithGem: String {
        return NSLocalizedString("msgf_bid_with_gem", comment: "")
    }
    var insufficientGemToUnlockDescription: String {
        return NSLocalizedString("msgf_insufficient_gem_unlock_des", comment: "")
    }
    var insufficientGemToBidDescription: String {
        return NSLocalizedString("msgf_insufficient_gem_bid_des", comment: "")
    }
    var earnBlueGemInstruction: String {
        return NSLocalizedString("msgf_earn_blue_gem_instruction", comment: "")
    }
    var receivedGem: String {
        return NSLocalizedString("msgf_received_gem", comment: "")
    }
    var unlockSucceeded: String {
        return NSLocalizedString("msgf_unlock_succeeded", comment: "")
    }
    var bidSucceeded: String {
        return NSLocalizedString("msgf_bid_succeeded", comment: "")
    }
    var startFollowingYou: String {
        return NSLocalizedString("msgf_start_following_you", comment: "")
    }
    var likedYourPost: String {
        return NSLocalizedString("msgf_liked_your_post", comment: "")
    }
    var gaveYouNumberGems: String {
        return NSLocalizedString("msgf_you_received_num_gems", comment: "")
    }
    var postReported: String {
        return NSLocalizedString("msgf_post_reported", comment: "")
    }
    var profileReported: String {
        return NSLocalizedString("msgf_profile_reported", comment: "")
    }
    var likedYourPostAndGaveGem: String {
        return NSLocalizedString("msgf_liked_your_post_and_gave_gem", comment: "")
    }
    var thankYouForReportUser: String {
        return NSLocalizedString("msgf_thankyou_report_user", comment: "")
    }
    var unblockUserPrompt: String {
        return NSLocalizedString("msgf_unblock_user_prompt", comment: "")
    }
    var blockUserPrompt: String {
        return NSLocalizedString("msgf_block_user_prompt", comment: "")
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
    var unfollow: String {
        return NSLocalizedString("ph_unfollow", comment: "")
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
    var joinPrompt: String {
        return NSLocalizedString("ph_join_prompt", comment: "")
    }
    var shippingInfo: String {
        return NSLocalizedString("ph_shipping_info", comment: "")
    }
    var createShippingInfo: String {
        return NSLocalizedString("ph_create_shipping_info", comment: "")
    }
    var editShippingInfo: String {
        return NSLocalizedString("ph_edit_shipping_info", comment: "")
    }
    var viewShippingStatus: String {
        return NSLocalizedString("ph_view_shipping_status", comment: "")
    }
    var commodities: String {
        return NSLocalizedString("ph_commodities", comment: "")
    }
    var biddingProcess: String {
        return NSLocalizedString("ph_bidding_process", comment: "")
    }
    var bidCount: String {
        return NSLocalizedString("ph_bid_count", comment: "")
    }
    var countdown: String {
        return NSLocalizedString("ph_countdown", comment: "")
    }
    var bidLeader: String {
        return NSLocalizedString("ph_bid_leader", comment: "")
    }
    var productName: String {
        return NSLocalizedString("ph_product_name", comment: "")
    }
    var bidOutcome: String {
        return NSLocalizedString("ph_bid_outcome", comment: "")
    }
    var bidLot: String {
        return NSLocalizedString("ph_bid_lot", comment: "")
    }
    var successfulShippingInfoSubmission: String {
        return NSLocalizedString("ph_successful_shipping_info_submission", comment: "")
    }
    var goToBiddingPage: String {
        return NSLocalizedString("ph_goto_bidding", comment: "")
    }
    var getGem: String {
        return NSLocalizedString("ph_get_gem", comment: "")
    }
    var hasGotGem: String {
        return NSLocalizedString("ph_has_got_gem", comment: "")
    }
    var newNotices: String {
        return NSLocalizedString("ph_new_notices", comment: "")
    }
    var readNotices: String {
        return NSLocalizedString("ph_read_notices", comment: "")
    }
    var recoverAccount: String {
        return NSLocalizedString("ph_recover_account", comment: "")
    }
    var petitionSubmitted: String {
        return NSLocalizedString("ph_petition_submitted", comment: "")
    }
    var iGetIt: String {
        return NSLocalizedString("ph_i_get_it", comment: "")
    }
    var unlockOptionPrompt: String {
        return NSLocalizedString("ph_unlock_option_prompt", comment: "")
    }
    var latestPosts: String {
        return NSLocalizedString("ph_latest_posts", comment: "")
    }
    var bestPosts: String {
        return NSLocalizedString("ph_best_posts", comment: "")
    }
    var thanksForReportingPost: String {
        return NSLocalizedString("ph_thanks_for_reporting_post", comment: "")
    }
    var showPost: String {
        return NSLocalizedString("ph_show_post", comment: "")
    }
    var more: String {
        return NSLocalizedString("ph_more", comment: "")
    }
}

class LocalizedPhraseFormats {//phf_
    fileprivate init() {}
    var secondsAgoShort: String {
        return NSLocalizedString("phf_seconds_ago_short", comment: "")
    }
    var minutesAgoShort: String {
        return NSLocalizedString("phf_minutes_ago_short", comment: "")
    }
    var hoursAgoShort: String {
        return NSLocalizedString("phf_hours_ago_short", comment: "")
    }
    var daysAgoShort: String {
        return NSLocalizedString("phf_days_ago_short", comment: "")
    }
    var secondsAgo: String {
        return NSLocalizedString("phf_seconds_ago", comment: "")
    }
    var minutesAgo: String {
        return NSLocalizedString("phf_minutes_ago", comment: "")
    }
    var hoursAgo: String {
        return NSLocalizedString("phf_hours_ago", comment: "")
    }
    var daysAgo: String {
        return NSLocalizedString("phf_days_ago", comment: "")
    }
    var followers: String {
        return NSLocalizedString("phf_followers", comment: "")
    }
    var followings: String {
        return NSLocalizedString("phf_followings", comment: "")
    }
}

class EmptyMessages {//no_
    var posts: String {
        return NSLocalizedString("no_posts", comment: "")
    }
    var promoPopups: String {
        return NSLocalizedString("no_promo_popups", comment: "")
    }
    var unlockedLotsTitle: String {
        return NSLocalizedString("no_unlocked_lots_title", comment: "")
    }
    var unlockedLotsMessage: String {
        return NSLocalizedString("no_unlocked_lots_message", comment: "")
    }
    var notices: String {
        return NSLocalizedString("no_notices", comment: "")
    }
    var blockList: String {
        return NSLocalizedString("no_block_list", comment: "")
    }
    var followerList: String {
        return NSLocalizedString("no_follower_list", comment: "")
    }
    var followingList: String {
        return NSLocalizedString("no_following_list", comment: "")
    }
}

class LocalizedErrorsTitles {//errtl_
    fileprivate init() {}
    var genericFailure: String {
        return NSLocalizedString("errtl_generic_failure", comment: "")
    }

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
    var nonDigitInput: String {
        return NSLocalizedString("err_non_digit_input", comment: "")
    }
    var accountDoesnotExist: String {
        return NSLocalizedString("err_account_not_exist", comment: "")
    }
    var invalidNickname: String {
        return NSLocalizedString("err_invalid_nickname", comment: "")
    }
    var invalidPhoneNumber: String {
        return NSLocalizedString("err_invalid_phone_number", comment: "")
    }
}

class GemStonePopUp { //pop
    fileprivate init() {}
    var blueGemUsage: String {
        return NSLocalizedString("pop_blue_gem_usage", comment: "")
    }
    var greenGemUsage: String {
        return NSLocalizedString("pop_green_gem_usage", comment: "")
    }
    var purpleGemUsage: String {
        return NSLocalizedString("pop_purple_gem_usage", comment: "")
    }
    var blueGemAction: String {
        return NSLocalizedString("pop_blue_gem_action", comment: "")
    }
    var greenGemAction: String {
        return NSLocalizedString("pop_green_gem_action", comment: "")
    }
    var blueGemBullet1: String {
        return NSLocalizedString("pop_blue_gem_bullet1", comment: "")
    }
    var blueGemBullet2: String {
        return NSLocalizedString("pop_blue_gem_bullet2", comment: "")
    }
    var blueGemBullet3: String {
        return NSLocalizedString("pop_blue_gem_bullet3", comment: "")
    }
    var greenGemBullet1: String {
        return NSLocalizedString("pop_green_gem_bullet1", comment: "")
    }
    var greenGemBullet2: String {
        return NSLocalizedString("pop_green_gem_bullet2", comment: "")
    }
    var greenGemBullet3: String {
        return NSLocalizedString("pop_green_gem_bullet3", comment: "")
    }
    var greenGemBullet4: String {
        return NSLocalizedString("pop_green_gem_bullet4", comment: "")
    }
    var purpleGemBullet1: String {
        return NSLocalizedString("pop_purple_gem_bullet1", comment: "")
    }
    var purpleGemBullet2: String {
        return NSLocalizedString("pop_purple_gem_bullet2", comment: "")
    }
}

class LocalizedShippingInfoTerms {//ship_
    fileprivate init() {}
    var email: String {
        return Localized.titles.email
    }
    var firstName: String {
        return NSLocalizedString("ship_first_name", comment: "")
    }
    var lastName: String {
        return NSLocalizedString("ship_last_name", comment: "")
    }
    var address1: String {
        return NSLocalizedString("ship_address1", comment: "")
    }
    var address2: String {
        return NSLocalizedString("ship_address2", comment: "")
    }
    var city: String {
        return NSLocalizedString("ship_city", comment: "")
    }
    var region: String {
        return NSLocalizedString("ship_region", comment: "")
    }
    var postalCode: String {
        return NSLocalizedString("ship_postal_code", comment: "")
    }
    var country: String {
        return NSLocalizedString("ship_country", comment: "")
    }
    var phoneNumber: String {
        return NSLocalizedString("ship_phoneNumber", comment: "")
    }
}

class LocalizedReportReasons { //rp_
    fileprivate init() {}
    var termsViolation: String {
        return NSLocalizedString("rp_terms_violation", comment: "")
    }
    
    var dontLikePostTitle: String {
        return NSLocalizedString("rp_dont_like_post_title", comment: "")
    }
    var dontLikePostDetail: String {
        return NSLocalizedString("rp_dont_like_post_detail", comment: "")
    }
    var nudityTitle: String {
        return NSLocalizedString("rp_dnudity_title", comment: "")
    }
    var nudityDetail: String {
        return NSLocalizedString("rp_dnudity_detail", comment: "")
    }
    var hateSpeechTitle: String {
        return NSLocalizedString("rp_hate_speech_title", comment: "")
    }
    var hateSpeechDetail: String {
        return NSLocalizedString("rp_hate_speech_detail", comment: "")
    }
    var hateSpeechSubtitle: String {
        return NSLocalizedString("rp_hate_speech_subtitle", comment: "")
    }
    var violanceTitle: String {
        return NSLocalizedString("rp_violance_title", comment: "")
    }
    var violanceDetail: String {
        return NSLocalizedString("rp_violance_detail", comment: "")
    }
    var violanceSubtitle: String {
        return NSLocalizedString("rp_violance_subtitle", comment: "")
    }
}


class LocalizedSimbols { //smb_
    var enumSpliter: String {
        return NSLocalizedString("smb_enum_spliter", comment: "")
    }
}
