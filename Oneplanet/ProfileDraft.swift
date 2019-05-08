//
//  ProfileDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/2.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class ProfileDraft {
    let updateObservers = MulticastCallbackNode<()->()>()
    let intermediateNicknameValidator = InputLengthValidator(max: 30)
    let nicknameValidator = AndValidator([NonEmptyInputValidator(), InputLengthValidator(max: 30), NicknameInputValidator()])
    var nickname: String = "" {
        didSet {
            if oldValue != nickname {
                updateObservers.invokeEach{$0()}
            }
        }
    }
    var avatar: UIImage?
    
    func validate() throws {
        try nicknameValidator.validate(nickname)
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

class CreateProfileOperation: AlamofireAPIAccessOperation {
    let draft: ProfileDraft
    let session: UserSession
    init(draft: ProfileDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
}

class DownloadImageOperaion: AlamofireAPIAccessOperation {
    let url: URL
    private(set) var image: UIImage?
    init(url: URL) {
        self.url = url
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: url)
    }
    
    override func processData(with data: Data) throws {
        image = UIImage(data: data)
    }
}
