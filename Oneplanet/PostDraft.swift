//
//  PostDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/7.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class PostDraft {
    let isValued: Bool
    var images: [ImageAttachment] = []
    var caption: String = ""
    var captionValidator = InputLengthValidator(max: 200)
    
    init(isValued: Bool) {
        self.isValued = isValued
    }

    func validate() throws {
        try captionValidator.validate(caption)
    }
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch _ {
            return false
        }
    }
}

class SubmitPostDraftOperation: SimpleAsynchronousOperation, FailableOperationType {
    let draft: PostDraft
    let session: UserSession
    private(set) var success: Bool?
    private(set) var error: Error?

    init(draft: PostDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
}
