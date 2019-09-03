//
//  ImageAttachmentUploadFlowOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/7.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Alamofire
import ModelBlocks
import ImageIO

class ImageAttachment {
    let localImage: UIImage
    let progress: UploadProgress
    init(image: UIImage) {
        localImage = image
        progress = UploadProgress()
    }
    
    init(image: UIImage, info: WebImageInfo) {
        localImage = image
        progress = UploadProgress()
        progress.didGenerateDestination(UploadDestination(taskId: "", url: info.url))
        progress.markAsFinished()
    }
}

class ImageAttachmentUploadFlowOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    let session: UserSession
    let attachment: ImageAttachment
    let preset: ProcessImageOperation.Preset
    let generatorURL: URL
    
    private var generaUploadURLOperation: GenerateUploadURLOperation?
    private var uploadImageOperation: UploadImageOperation?
    
    init(attachment: ImageAttachment, preset: ProcessImageOperation.Preset, generatorURL: URL, session: UserSession) {
        self.session = session
        self.preset = preset
        self.generatorURL = generatorURL
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
        if let meta = attachment.progress.metadata {
            generateUploadURL(with: meta)
            return
        }
        processImage()
    }
    
    private func processImage() {
        let op = ProcessImageOperation(attachment: attachment, preset: preset)
        op.start()
        if let data = op.data, let meta = op.metadata {
            attachment.progress.didProcessImage(to: data, metadata: meta)
            runNext()
        } else {
            fail(with: op.error)
        }
    }

    private func generateUploadURL(with meta: FileMetadata) {
        let op = GenerateUploadURLOperation(generatorURL: generatorURL, imageMetadata: meta, session: session)
        op.completionBlock = {[weak self] in
            self?.didGenerateUploadURL()
        }
        generaUploadURLOperation = op
        op.start()
    }
    
    private func didGenerateUploadURL() {
        let op = generaUploadURLOperation!
        if let dst = op.destination {
            attachment.progress.didGenerateDestination(dst)
            runNext()
        } else {
            fail(with: op.error)
        }
    }

    private func uploadImageData(_ data: Data, withMetadata metadata: FileMetadata, to destination: UploadDestination) {
        let op = UploadImageOperation(destination: destination, imageData: data, imageMetadata: metadata)
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
            if !op.isDestinationValid {
                attachment.progress.invalidateDestinationIfAllowed()
            }
            fail(with: op.error)
        }
    }

    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
    
    override func onCancel() {
        generaUploadURLOperation?.cancel()
        uploadImageOperation?.cancel()
    }
}

class ProcessImageOperation: Operation {
    let attachment: ImageAttachment
    let preset: Preset
    private(set) var data: Data?
    private(set) var metadata: FileMetadata?
    private(set) var error: Error?

    init(attachment: ImageAttachment, preset: Preset) {
        self.attachment = attachment
        self.preset = preset
    }

    override func main() {
        guard !isCancelled else { return }
        guard let data = UIImage.jpegData(attachment.localImage)(compressionQuality: 1),
            let resizedImage = resizeImage(from: data),
            let resizedData = UIImage.jpegData(resizedImage)(compressionQuality: preset.compressionQuality) else {
            error = GenericAppError("Cannot process image")
            return
        }
        self.data = resizedData
        metadata = FileMetadata(mimeType: "image/jpeg", size: resizedData.count)
    }
    
    private func resizeImage(from dat: Data) -> UIImage? {
        guard let src = CGImageSourceCreateWithData(dat as CFData, nil) else {
            return nil
        }
        let op : [NSObject:AnyObject] =
            [kCGImageSourceShouldAllowFloat: true as AnyObject,
             kCGImageSourceCreateThumbnailWithTransform: true as AnyObject,
             kCGImageSourceCreateThumbnailFromImageAlways: true as AnyObject,
             kCGImageSourceThumbnailMaxPixelSize: preset.maxSize as AnyObject]
        guard let cgImg = CGImageSourceCreateThumbnailAtIndex(src, 0, op as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImg)
    }
}

extension ProcessImageOperation {
    struct Preset {
        let compressionQuality: CGFloat
        let maxSize: CGFloat
    }
}

fileprivate class GenerateUploadURLOperation: AlamofireAPIAccessOperation {
    let session: UserSession
    let generatorURL: URL
    let imageMetadata: FileMetadata
    private(set) var destination: UploadDestination?
    
    init(generatorURL: URL, imageMetadata: FileMetadata, session: UserSession) {
        self.generatorURL = generatorURL
        self.imageMetadata = imageMetadata
        self.session = session
    }
}

fileprivate class UploadImageOperation: AlamofireAPIAccessOperation {
    let destination: UploadDestination
    let imageData: Data
    let imageMetadata: FileMetadata
    private(set) var isDestinationValid = true

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
    
    override func handleClientError(with response: HTTPURLResponse) throws {
        if response.statusCode == 403 {
            isDestinationValid = false
        }
        try super.handleClientError(with: response)
    }
}

class UploadProgress {
    private(set) var data: Data?
    private(set) var metadata: FileMetadata?
    
    func didProcessImage(to data: Data, metadata: FileMetadata) {
        self.data = data
        self.metadata = metadata
    }
    
    private(set) var uploadDestination: UploadDestination?
    private(set) var imageLocation: UploadDestination?

    func didGenerateDestination(_ des: UploadDestination) {
        uploadDestination = des
    }
    
    func invalidateDestinationIfAllowed() {
        guard imageLocation == nil else {
            return
        }
        
        uploadDestination = nil
    }
    
    func markAsFinished(with finalLocation: UploadDestination? = nil) {
            imageLocation = finalLocation ?? uploadDestination
    }
    
    var isFinished: Bool {
        return imageLocation != nil
    }
}

class FileMetadata {
    let mimeType: String
    let size: Int
    
    init(mimeType: String, size: Int) {
        self.mimeType = mimeType
        self.size = size
    }
}

class UploadDestination {
    let taskId: String
    let url: URL
    init(taskId: String, url: URL) {
        self.taskId = taskId
        self.url = url
    }
}
