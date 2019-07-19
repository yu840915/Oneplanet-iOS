//
//  ReportHelpers.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation

class ReportFlowController {
    var headerTitle: String {
        return ""
    }
    var predefinedReasons: [ReportDraft.Reason] {
        return []
    }
    var reportCaption: String {
        return ""
    }
    var shouldShowThankYouPage: Bool {
        return false
    }
    var isReporting: Bool {
        return false
    }
    
    func submit(_ draft: ReportDraft, completion: @escaping ((Bool, Error?)->())) {
    }
}

class PostReportFlowController: ReportFlowController {
    override var headerTitle: String {
        return Localized.messages.reportPostPrompt
    }
    override var predefinedReasons: [ReportDraft.Reason] {
        return [
            .init(id: "1", title: Localized.reportReasons.dontLikePostTitle, subtitle: "", detail: Localized.reportReasons.dontLikePostDetail),
            .init(id: "2", title: Localized.reportReasons.nudityTitle, subtitle: "", detail: Localized.reportReasons.nudityDetail),
            .init(id: "3", title: Localized.reportReasons.hateSpeechTitle, subtitle: Localized.reportReasons.hateSpeechSubtitle, detail: Localized.reportReasons.hateSpeechDetail),
            .init(id: "4", title: Localized.reportReasons.violanceTitle, subtitle: Localized.reportReasons.violanceSubtitle, detail: Localized.reportReasons.violanceDetail)
        ]
    }
    override var reportCaption: String {
        return Localized.messages.reportPostCaption
    }
    override var shouldShowThankYouPage: Bool {
        return false
    }
    
    override func submit(_ draft: ReportDraft, completion: @escaping ((Bool, Error?) -> ())) {
        if draft.isReady {
        } else {
            completion(false, GenericAppError("Input is not ready"))
        }
    }
}

class UserReportFlowController: ReportFlowController {
    override var headerTitle: String {
        return Localized.messages.reportUserPrompt
    }
    override var predefinedReasons: [ReportDraft.Reason] {
        return [.init(id: "123", title: Localized.reportReasons.termsViolation)]
    }
    override var reportCaption: String {
        return Localized.messages.reportUserCaption
    }
    override var shouldShowThankYouPage: Bool {
        return true
    }
    
    override func submit(_ draft: ReportDraft, completion: @escaping ((Bool, Error?) -> ())) {
        if draft.isReady {
        } else {
            completion(false, GenericAppError("Input is not ready"))
        }
    }
}

class ReportDraft {
    var didUpdate: (()->())?
    var reason: Reason? {
        didSet {
            didUpdate?()
        }
    }
    var description : String = "" {
        didSet {
            didUpdate?()
        }
    }
    var isReady: Bool {
        return reason != nil && !description.isEmpty
    }
    
    class Reason {
        let id: String
        let title: String
        let subtitle: String
        let detail: String
        
        init(id: String, title: String, subtitle: String = "", detail: String = "") {
            self.id = id
            self.title = title
            self.subtitle = subtitle
            self.detail = detail
        }
    }
}
