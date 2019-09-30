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
    let originalPost: Post?
    let isValued: Bool
    var images: [ImageAttachment] = []
    var caption: String = ""
    var captionValidator = InputLengthValidator(max: 200)
    var updatedPost: Post? {
        if let post = originalPost {
            return Post(post: post, caption: caption)
        } else {
            return nil
        }
    }
    
    init(isValued: Bool) {
        self.isValued = isValued
        originalPost = nil
    }
    
    init(post: Post) {
        originalPost = post
        isValued = post.type == PostType.valued.rawValue
        caption = post.caption
    }

    func validate() throws {
        try captionValidator.validate(caption)
        if originalPost == nil && images.isEmpty {
            throw GenericAppError("Image cannot be empty")
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
}

class SubmitPostOperation: SimpleAsynchronousOperation, FailableOperationType {
    let draft: PostDraft
    let session: UserSession
    private(set) var success: Bool?
    private(set) var error: Error?
    private var uploadImageOperations: ConcurrentTaskOperation<UpdatePostPhotoFlowOperaion>?
    private var submitDraftOperations: SubmitPostDraftOperation?

    init(draft: PostDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func main() {
        guard !isCancelled else {return}
        do {
            try draft.validate()
            if draft.originalPost == nil {
                uploadImages()
            } else {
                submitDraft()
            }
        } catch let error {
            fail(with: error)
        }
    }
    
    private func uploadImages() {
        let preset = ProcessImageOperation.Preset(compressionQuality: 1.0, maxSize: 750)
        let op = ConcurrentTaskOperation<UpdatePostPhotoFlowOperaion>(operations: draft.images.map{UpdatePostPhotoFlowOperaion(attachment: $0, preset: preset, session: session)})
        op.completionBlock = {[weak self] in
            self?.didUploadImages()
        }
        uploadImageOperations = op
        op.start()
    }
    
    private func didUploadImages() {
        guard !isCancelled else {return}
        let op = uploadImageOperations!
        if op.success == true {
            submitDraft()
        } else {
            fail(with: op.error)
        }
    }
    
    private func submitDraft() {
        let op = SubmitPostDraftOperation(draft: draft, session: session)
        op.completionBlock = {[weak self] in
            self?.didSubmitDraft()
        }
        submitDraftOperations = op
        op.start()
    }
    
    private func didSubmitDraft() {
        guard !isCancelled else {return}
        let op = submitDraftOperations!
        success = op.success
        error = op.error
        finish()
    }
    
    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}

class SubmitPostDraftOperation: AlamofireAPIAccessOperation {
    let draft: PostDraft
    let session: UserSession
    private(set) var post: Post?
    typealias Keys = Post.CodingKeys

    init(draft: PostDraft, session: UserSession) {
        self.draft = draft
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        var url = ServiceURLs.base.appendingPathComponent("posts")
        var method = HTTPMethod.post
        if let post = draft.originalPost {
            url.appendPathComponent(post.id)
            method = .put
        }
        return Alamofire.request(url, method: method, parameters: try prepareParameters(), encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    private func prepareParameters() throws -> Parameters {
        var images: [URL] = []
        
        if let post = draft.originalPost {
            images = post.imageURLs
        } else {
            images = draft.images.compactMap{$0.progress.imageLocation?.url}
        }
        return [Keys.caption.rawValue: draft.caption,
                Keys.imageURLs.rawValue: images.map{$0.absoluteString},
                Keys.type.rawValue: draft.isValued ? PostType.valued.rawValue : PostType.free.rawValue]
    }
    
    override func processData(with data: Data) throws {
        if data.isEmpty { return }
        post = try JSONDecoder.default.decode(Post.self, from: data)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}

class UpdatePostPhotoFlowOperaion: SimpleAsynchronousOperation, FailableOperationType {
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

class UploadPostPhotoOperation: AlamofireAPIAccessOperation {
    let destination: UploadDestination
    let imageData: Data
    let imageMetadata: FileMetadata
    let session: UserSession
    private(set) var finalLocation: UploadDestination?
    
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
                                method: .post,
                                headers: header)
    }
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        guard let loc = header["Location"] as? String, let url = URL(string: loc) else {
            throw GenericAppError("Missing image location")
        }
        finalLocation = UploadDestination(taskId: destination.taskId, url: url)
    }
}

class ConcurrentTaskOperation<TaskType>: SimpleAsynchronousOperation, FailableOperationType where TaskType: SimpleAsynchronousOperation, TaskType: FailableOperationType {
    let operations: [TaskType]
    
    init(operations: [TaskType]) {
        self.operations = operations
    }
    var error: Error? {
        return operations.first{$0.error != nil}?.error
    }
    var success: Bool? {
        return operations.filter{$0.success == true}.count == operations.count
    }
    
    override func main() {
        guard !operations.isEmpty else {
            finish()
            return
        }
        operations.forEach {(op) in
            op.completionBlock = { [weak self] in
                OperationQueue.main.addOperation {
                    self?.finishIfAllDone()
                }
            }
        }
        operations.forEach { $0.start() }
    }
    
    override func onCancel() {
        operations.forEach{$0.cancel()}
    }
    
    private func finishIfAllDone() {
        guard !isCancelled && !isFinished else { return }
        guard operations.first(where: {!$0.isFinished}) == nil else {
            return
        }
        finish()
    }
}

class DeletePostOperation: AlamofireAPIAccessOperation {
    let post: Post
    let session: UserSession
    
    init(post: Post, session: UserSession) {
        self.post = post
        self.session = session
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        guard post.authorID == session.profile?.id else {
            throw GenericAppError("You can only delete your post")
        }
        return session.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("posts/\(post.id)"), method: .delete))
    }
    
    override func willFinishProcess() throws {
        OperationQueue.main.addOperation {[session, post] in
            session.notifyPostDidDelete(post)
        }
    }
}
