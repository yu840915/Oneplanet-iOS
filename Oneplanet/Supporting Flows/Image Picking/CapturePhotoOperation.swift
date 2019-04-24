//
//  CapturePhotoOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import AVFoundation

class CapturePhotoOperation: SimpleAsynchronousOperation, AVCapturePhotoCaptureDelegate {
    let captureOutput: AVCapturePhotoOutput
    let settings: AVCapturePhotoSettings
    fileprivate(set) var photo: AVCapturePhoto?
    fileprivate(set) var error: Error?
    
    init(captureOutput: AVCapturePhotoOutput, settings: AVCapturePhotoSettings) {
        self.captureOutput = captureOutput
        self.settings = AVCapturePhotoSettings(from: settings)
    }
    
    override func main() {
        guard !isCancelled else { return }
        captureOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard !isCancelled else { return }
        if let error = error {
            logger.debug("Cannot process photo, error: \(error)")
        }
        self.photo = photo
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        logger.info("Settings \(resolvedSettings)")
        self.error = error
        finish()
    }
}
