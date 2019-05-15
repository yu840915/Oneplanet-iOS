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

class UpdateProfileOperation: AlamofireAPIAccessOperation {
    let draft: ProfileDraft
    let session: UserSession
    init(draft: ProfileDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try draft.validate()
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("me"), method: .put, parameters: ["username": draft.nickname], encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
}

class UpdateMyAvatarFlowOperaion: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    let attachment: ImageAttachment
    let preset: ProcessImageOperation.Preset
    let session: UserSession
    
    private var uploadImageOperation: UploadMyAvatarOperation?

    init(attachment: ImageAttachment, preset: ProcessImageOperation.Preset, generatorURL: URL, session: UserSession) {
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
            
            attachment.progress.didGenerateDestination(UploadDestination(taskId: "", url: ServiceURLs.base.appendingPathComponent("me/avatar.jpg")))
            runNext()
        } else {
            fail(with: op.error)
        }
    }

    private func uploadImageData(_ data: Data, withMetadata metadata: FileMetadata, to destination: UploadDestination) {
        let op = UploadMyAvatarOperation(destination: destination, imageData: data, imageMetadata: metadata)
        op.completionBlock = {[weak self] in
            self?.didUpload()
        }
        uploadImageOperation = op
        op.start()
    }
    
    private func didUpload() {
        let op = uploadImageOperation!
        if op.success == true {
            attachment.progress.markAsFinished()
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
    
    init(destination: UploadDestination, imageData: Data, imageMetadata: FileMetadata) {
        self.destination = destination
        self.imageData = imageData
        self.imageMetadata = imageMetadata
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        return Alamofire.upload(imageData,
                                to: destination.url,
                                method: .put,
                                headers: [
                                    "Content-Type": imageMetadata.mimeType,
                                    "Content-Length": String(imageMetadata.size)])
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
