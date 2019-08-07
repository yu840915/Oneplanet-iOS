//
//  AskForAuthorizationOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import AVFoundation
import Photos

enum AuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    
    var shouldAskForAuthorization: Bool {
        return self == .notDetermined
    }
    
    static func from(_ status: AVAuthorizationStatus) -> AuthorizationStatus {
        switch status {
        case .authorized: return .authorized
        case .restricted, .denied: return .denied
        case .notDetermined: return .notDetermined
        }
    }
    
    static func from(_ status: PHAuthorizationStatus) -> AuthorizationStatus {
        switch status {
        case .authorized: return .authorized
        case .restricted, .denied: return .denied
        case .notDetermined: return .notDetermined
        }
    }
}

class AskForAuthorizationOperation: SimpleAsynchronousOperation {
    class var authorizationStatus: AuthorizationStatus {
        return .notDetermined
    }
    
    private(set) var authorizationStatus: AuthorizationStatus?
    fileprivate func updateStatus(_ status: AuthorizationStatus) {
        authorizationStatus = status
    }
}

class AskForCameraAuthorizationOperation: AskForAuthorizationOperation {
    override class var authorizationStatus: AuthorizationStatus {
        return AuthorizationStatus.from(AVCaptureDevice.authorizationStatus(for:  .video))
    }
    
    override func main() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {[weak self] allowed in
            self?.didRequestAccess(allowed)
        })
    }
    
    private func didRequestAccess(_ allowed: Bool) {
        updateStatus(allowed ? .authorized : .denied)
        finish()
    }
}

class AskForPhotoLibraryAuthorizationOperation: AskForAuthorizationOperation {
    override class  var authorizationStatus: AuthorizationStatus {
        return AuthorizationStatus.from(PHPhotoLibrary.authorizationStatus())
    }
    
    override func main() {
        PHPhotoLibrary.requestAuthorization {[weak self] status in
            self?.didRequestAccess(status)
        }
    }
    
    private func didRequestAccess(_ status: PHAuthorizationStatus) {
        updateStatus(AuthorizationStatus.from(PHPhotoLibrary.authorizationStatus()))
        finish()
    }
}

class AskForCameraAndLibraryAuthorizationOperation: SimpleAsynchronousOperation {
    let cameraAuthOperation: AskForCameraAuthorizationOperation
    let libraryAuthOperation: AskForPhotoLibraryAuthorizationOperation
    override init() {
        cameraAuthOperation = AskForCameraAuthorizationOperation()
        libraryAuthOperation = AskForPhotoLibraryAuthorizationOperation()
        super.init()
    }
    
    override func main() {
        guard !isCancelled else {return}
        cameraAuthOperation.completionBlock = {[weak self] in
            self?.askForLibraryAccess()
        }
        cameraAuthOperation.start()
    }
    
    private func askForLibraryAccess() {
        guard !isCancelled else {return}
        libraryAuthOperation.completionBlock = {[weak self] in
            self?.finish()
        }
        libraryAuthOperation.start()
    }
}
