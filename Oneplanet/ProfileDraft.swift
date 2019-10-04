//
//  ProfileDraft.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/2.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class ProfileDraft {
    private(set) var isDirty = false
    let updateObservers = MulticastCallbackNode<()->()>()
    let intermediateNicknameValidator = InputLengthValidator(max: 30)
    let nicknameValidator = AndValidator([NonEmptyInputValidator(), InputLengthValidator(max: 30), NicknameInputValidator()])
    let usernameValidator = AndValidator([InputLengthValidator(min: 5, max: 10), UsernameInputValidator()])
    let intermediateUsernameValidator = AndValidator([InputLengthValidator(max: 10), UsernameInputValidator()])
    
    var nickname: String = "" {
        didSet {
            if oldValue != nickname {
                notifyChange()
            }
        }
    }
    var username: String = "" {
        didSet {
            if oldValue != username {
                notifyChange()
            }
        }
    }
    var gender: Gender = .unknown {
        didSet {
            if oldValue != gender {
                notifyChange()
            }
        }
    }
    var avatar: ImageAttachment?  {
        didSet {
            if oldValue !== avatar {
                notifyChange()
            }
        }
    }
    var alien: Alien?
    
    func setDefaultAvatarIfAllowed(_ attachemnt: ImageAttachment) {
        guard avatar == nil else { return }
        avatar = attachemnt
        isDirty = false
    }
    
    private func notifyChange() {
        isDirty = true
        updateObservers.invokeEach{$0()}
    }
    
    func validate() throws {
        try validateField(.username, input: username, validator: usernameValidator)
        if !isAdmin {
            try validateField(.nickname, input: nickname, validator: nicknameValidator)
        }
    }
    
    private func validateField(_ field: Field, input: String, validator: TextInputValidator) throws {
        do {
            try validator.validate(input)
        } catch let error as NSError {
            throw ProfileDraftInputError(field: field, inputError: error)
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
    
    init(profile: MyProfile) {
        nickname = profile.nickname
        username = profile.username
        gender = profile.gender
        alien = profile.alien
        isAdmin = profile.isAdmin
    }
    let isAdmin: Bool
    
    enum Field {
        case username, nickname
    }
}

class ProfileDraftInputError: NSError {
    let field: ProfileDraft.Field
    let inputError: NSError
    init(field: ProfileDraft.Field, inputError: NSError) {
        self.field = field
        self.inputError = inputError
        super.init(domain: inputError.domain, code: inputError.code, userInfo: inputError.userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UpdateProfileOperation: SimpleAsynchronousOperation, FailableOperationType {
    let draft: ProfileDraft
    let session: UserSession
    private(set) var success: Bool?
    private(set) var error: Error?
    private var updateAvatarOperation: UpdateMyAvatarFlowOperaion?
    private var updateContentOperation: UpdateProfileContentOperation?

    init(draft: ProfileDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func main() {
        guard !isCancelled else {return}
        if let attachment = draft.avatar {
            uploadAvatar(with: attachment)
        } else {
            updateContent()
        }
    }
    
    private func uploadAvatar(with attachment: ImageAttachment) {
        let op = UpdateMyAvatarFlowOperaion(attachment: attachment, preset: ProcessImageOperation.Preset(compressionQuality: 1.0, maxSize: 256), session: session)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didUpdateAvatar()
            }
        }
        updateAvatarOperation = op
        op.start()
    }
    
    private func didUpdateAvatar() {
        let op = updateAvatarOperation!
        if op.success == true {
            updateContent()
        } else {
            fail(with: op.error)
        }
    }
    
    private func updateContent() {
        let op = UpdateProfileContentOperation(draft: draft, session: session)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didUpdateContent()
            }
        }
        updateContentOperation = op
        op.start()
    }
    
    private func didUpdateContent() {
        let op = updateContentOperation!
        success = op.success
        error = op.error
        finish()
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
    }
}

class UpdateProfileContentOperation: AlamofireAPIAccessOperation {
    let draft: ProfileDraft
    let session: UserSession
    init(draft: ProfileDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("me"), method: .put, parameters: try serializeProfileDraft(), encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    private func serializeProfileDraft() throws -> Parameters {
        try draft.validate()
        var result: Parameters = ["username": draft.username, "display_name": draft.nickname]
        if let gender = draft.gender.toString() {
            result["gender"] = gender
        }
        if let alien = draft.alien {
            result["alien"] = ["avatar": alien.race.rawValue, "color": alien.color.rawValue]
        }
        if let avatarURL = draft.avatar?.progress.imageLocation {
            result["avatar"] = avatarURL.url.absoluteString
        }
        return result
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}

class UpdateMyAvatarFlowOperaion: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    let attachment: ImageAttachment
    let preset: ProcessImageOperation.Preset
    let session: UserSession
    
    private var uploadImageOperation: UploadPhotoOperation?

    init(attachment: ImageAttachment, preset: ProcessImageOperation.Preset, session: UserSession) {
        self.session = session
        self.preset = preset
        self.attachment = attachment
    }

    override func main() {
        runNext()
    }
    
    private func runNext() {
        guard !isCancelled else { return }
        if attachment.progress.isFinished {
            success = true
            finish()
            return
        }
        if let dst = attachment.progress.uploadDestination,
            let data = attachment.progress.data,
            let meta = attachment.progress.metadata {
            uploadImageData(data, withMetadata: meta, to: dst)
            return
        }
        processImage()
    }
    
    private func processImage() {
        let op = ProcessImageOperation(attachment: attachment, preset: preset)
        op.start()
        if let data = op.data, let meta = op.metadata {
            attachment.progress.didProcessImage(to: data, metadata: meta)
            attachment.progress.didGenerateDestination(UploadDestination(taskId: "", url: ServiceURLs.base.appendingPathComponent("image/upload")))
            runNext()
        } else {
            fail(with: op.error)
        }
    }

    private func uploadImageData(_ data: Data, withMetadata metadata: FileMetadata, to destination: UploadDestination) {
        let op = UploadPhotoOperation(destination: destination, imageData: data, imageMetadata: metadata, session: session)
        op.completionBlock = {[weak self] in
            self?.didUpload()
        }
        uploadImageOperation = op
        op.start()
    }
    
    private func didUpload() {
        let op = uploadImageOperation!
        if op.success == true {
            attachment.progress.markAsFinished(with: op.finalLocation!)
            runNext()
        } else {
            fail(with: op.error)
        }
    }
    
    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
    
    override func onCancel() {
        uploadImageOperation?.cancel()
    }
}

class UploadMyAvatarOperation: AlamofireAPIAccessOperation {
    let destination: UploadDestination
    let imageData: Data
    let imageMetadata: FileMetadata
    let session: UserSession
    
    init(destination: UploadDestination, imageData: Data, imageMetadata: FileMetadata, session: UserSession) {
        self.destination = destination
        self.imageData = imageData
        self.imageMetadata = imageMetadata
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        let header = session.addingAuthorizationToken(to:
            ["Content-Type": imageMetadata.mimeType,
            "Content-Length": String(imageMetadata.size)])
        return Alamofire.upload(imageData,
                                to: destination.url,
                                method: .put,
                                headers: header)
    }
    
    override func handleClientError(with response: HTTPURLResponse) throws {
        try super.handleClientError(with: response)
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}


class DownloadImageOperaion: AlamofireAPIAccessOperation {
    let info: WebImageInfo
    private(set) var image: UIImage?
    init(info: WebImageInfo) {
        self.info = info
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        var req = URLRequest(url: info.url)
        if let token = info.accessToken {
            req.setValue(token, forHTTPHeaderField: "Authorization")
        }
        return req
    }
    
    override func processData(with data: Data) throws {
        image = UIImage(data: data)
    }
}
