//
//  UploadPhotoOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import ModelBlocks

class UploadPhotoOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    let destination: UploadDestination
    let imageData: Data
    let imageMetadata: FileMetadata
    let session: UserSession
    private(set) var finalLocation: UploadDestination?
    private var uploadRequest: UploadRequest?

    init(destination: UploadDestination, imageData: Data, imageMetadata: FileMetadata, session: UserSession) {
        self.destination = destination
        self.imageData = imageData
        self.imageMetadata = imageMetadata
        self.session = session
    }
    
    override func main() {
        Alamofire.upload(multipartFormData: {[weak self] (formdata) in
            self?.prepareFormdata(formdata)
        }, usingThreshold: SessionManager.multipartFormDataEncodingMemoryThreshold, to: destination.url, method: .post, headers: session.authorizationHeader) {[weak self] (result) in
            switch result {
            case .success(let request, _, _):
                self?.startUploadRequest(request)
            case .failure(let error):
                self?.fail(with: error)
            }
        }
    }
    
    private func prepareFormdata(_ formdata: MultipartFormData) {
        formdata.append(imageData, withName: "images", fileName: "images.jpg" , mimeType: imageMetadata.mimeType)
    }
    
    private func startUploadRequest(_ request: UploadRequest) {
        guard !isCancelled else {return}
        uploadRequest = request
        request.responseData {[weak self] (response) in
            self?.handleResponse(response)
        }
    }
    
    private func handleResponse(_ dataResponse: DataResponse<Data>) {
        guard !isCancelled else {return}
        guard let response = dataResponse.response else {
            fail(with: dataResponse.error)
            return
        }
        switch response.statusCode {
        case 200..<300:
            processHTTPResponseHeader(response.allHeaderFields)
        default:
            fail(with: GenericHTTPResponseError(response: response))
        }
    }
    
    private func processHTTPResponseHeader(_ header: [AnyHashable : Any]) {
        guard let loc = header["Location"] as? String, let url = URL(string: loc) else {
            fail(with: GenericAppError("Missing image location"))
            return
        }
        finalLocation = UploadDestination(taskId: destination.taskId, url: url)
        success = true
        finish()
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
        logger.error("Image upload failed, error: \(error)", context: error)
    }
}
