//
//  ReportHelpers.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import ModelBlocks

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
    private var reportOperation: ReportOperation?
    let session: UserSession
    let post: Post
    init(post: Post, session: UserSession) {
        self.session = session
        self.post = post
    }
    override var headerTitle: String {
        return Localized.messages.reportPostPrompt
    }
    override var predefinedReasons: [ReportDraft.Reason] {
        return [
            .init(id: "rp_dont_like_post", title: Localized.reportReasons.dontLikePostTitle, subtitle: "", detail: Localized.reportReasons.dontLikePostDetail),
            .init(id: "rp_nudity", title: Localized.reportReasons.nudityTitle, subtitle: "", detail: Localized.reportReasons.nudityDetail),
            .init(id: "rp_hate_speech", title: Localized.reportReasons.hateSpeechTitle, subtitle: Localized.reportReasons.hateSpeechSubtitle, detail: Localized.reportReasons.hateSpeechDetail),
            .init(id: "rp_violance", title: Localized.reportReasons.violanceTitle, subtitle: Localized.reportReasons.violanceSubtitle, detail: Localized.reportReasons.violanceDetail)
        ]
    }
    override var reportCaption: String {
        return Localized.messages.reportPostCaption
    }
    override var shouldShowThankYouPage: Bool {
        return false
    }
    
    override func submit(_ draft: ReportDraft, completion: @escaping ((Bool, Error?) -> ())) {
        guard reportOperation == nil else { return }
        if draft.isReady {
            let op = ReportOperation.forPost(post, draft: draft, session: session)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.didFinishReport(with: completion)
                }
            }
            reportOperation = op
            op.start()
        } else {
            completion(false, GenericAppError("Input is not ready"))
        }
    }
    
    private func didFinishReport(with completion: @escaping ((Bool, Error?) -> ())) {
        let op = reportOperation!
        reportOperation = nil
        let success = op.success ?? false
        if success {
            session.hiddenPosts.hide(post)
        }
        completion(success, op.error)
    }
}

class UserReportFlowController: ReportFlowController {
    private var reportOperation: ReportOperation?
    let session: UserSession
    let user: User
    init(user: User, session: UserSession) {
        self.session = session
        self.user = user
    }
    
    override var headerTitle: String {
        return Localized.messages.reportUserPrompt
    }
    override var predefinedReasons: [ReportDraft.Reason] {
        return [.init(id: "rp_terms", title: Localized.reportReasons.termsViolation)]
    }
    override var reportCaption: String {
        return Localized.messages.reportUserCaption
    }
    override var shouldShowThankYouPage: Bool {
        return true
    }
    
    override func submit(_ draft: ReportDraft, completion: @escaping ((Bool, Error?) -> ())) {
        guard reportOperation == nil else { return }
        if draft.isReady {
            let op = ReportOperation.forUser(user, draft: draft, session: session)
            op.completionBlock = {[weak self] in
                self?.didFinishReport(with: completion)
            }
            reportOperation = op
            op.start()
        } else {
            completion(false, GenericAppError("Input is not ready"))
        }
    }
    
    private func didFinishReport(with completion: @escaping ((Bool, Error?) -> ())) {
        let op = reportOperation!
        reportOperation = nil
        let success = op.success ?? false
        completion(success, op.error)
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

class ReportOperation: AlamofireAPIAccessOperation {
    let url: URL
    let draft: ReportDraft
    let session: UserSession
    
    class func forUser(_ user: User, draft: ReportDraft, session: UserSession) -> ReportOperation {
        return ReportOperation(url: ServiceURLs.base.appendingPathComponent("report/user/\(user.id)"), draft: draft, session: session)
    }
    
    class func forPost(_ post: Post, draft: ReportDraft, session: UserSession) -> ReportOperation {
        return ReportOperation(url: ServiceURLs.base.appendingPathComponent("report/post/\(post.id)"), draft: draft, session: session)
    }
    
    private init(url: URL, draft: ReportDraft, session: UserSession) {
        self.url = url
        self.draft = draft
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        guard let reason = draft.reason else {
            throw GenericAppError("Missing reason")
        }
        let params: Parameters = ["reason": reason.id, "title": reason.title, "subtitle": reason.subtitle, "message": draft.description]
        return Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding(), headers: session.authorizationHeader)
    }
}
