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
    static let phrase = LocalizedPhrase()
    static let activity = LocalizedActivityMessages()
}

class LocalizedTitles {//tl_
    var cancel: String {
        return NSLocalizedString("tl_cancel", comment: "")
    }
    var dismiss: String {
        return NSLocalizedString("tl_dismiss", comment: "")
    }
    var done: String {
        return NSLocalizedString("tl_done", comment: "")
    }
    var allPhotos: String {
        return NSLocalizedString("tl_all_photos", comment: "")
    }
}

class LocalizedActivityMessages {//act_
}

class LocalizedWarnings {//warn_
}

class LocalizedMessages {//msg_
}

class LocalizedPhrase { //ph_
}

class LocalizedErrorsTitles {//errtl_
    var cannotCapturePhoto: String {
        return NSLocalizedString("errtl_cannot_capture_photo", comment: "")
    }

}

class LocalizedErrors {//err_
    var noCameraAccess: String {
        return NSLocalizedString("err_no_camera_access", comment: "")
    }
}
