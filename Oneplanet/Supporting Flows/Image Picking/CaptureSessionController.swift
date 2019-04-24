//
//  CaptureSessionController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import AVFoundation
import ModelBlocks

class CaptureSessionController {
    let captureSession: AVCaptureSession
    let photoOutput: AVCapturePhotoOutput
    let photoSettings = AVCapturePhotoSettings()
    let cameraControllers: [CameraController]
    let didCapturePhotoObservers = MulticastCallbackNode<(AVCapturePhoto?, Error?)->()>()
    private var captureOperation: CapturePhotoOperation?
    var currentCamera: CameraController? {
        return cameraControllers.first {captureSession.inputs.contains($0.deviceInput)}
    }
    var canSwitchCamera: Bool {
        if currentCamera == nil {
            return !cameraControllers.isEmpty
        } else {
            return cameraControllers.count > 1
        }
    }
    var hasFlash: Bool {
        return currentCamera?.hasFlash ?? false
    }
    var isFlashOn: Bool {
        get {
            return photoSettings.flashMode == .on || photoSettings.flashMode == .auto
        }
        set {
            photoSettings.flashMode =  newValue ? .on : .off
        }
    }
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    init(captureSession: AVCaptureSession, photoOutput: AVCapturePhotoOutput, cameraControllers: [CameraController]) {
        self.captureSession = captureSession
        self.photoOutput = photoOutput
        self.cameraControllers = cameraControllers
    }
    
    func startRunning() {
        captureSession.startRunning()
    }
    
    func stopRunning() {
        captureSession.stopRunning()
    }
    
    func switchToCamera(_ camera: CameraController) {
        guard currentCamera !== camera else {
            return
        }
        if let currentInput = currentCamera?.deviceInput {
            captureSession.removeInput(currentInput)
        }
        captureSession.addInput(camera.deviceInput)
    }
    
    func takePhotoIfReady() {
        guard captureOperation == nil else { return }
        let op = CapturePhotoOperation(captureOutput: photoOutput, settings: photoSettings)
        op.completionBlock = {[weak self] in
            self?.didTakePhoto()
        }
        captureOperation = op
        op.start()
    }
    
    private func didTakePhoto() {
        let op = captureOperation!
        captureOperation = nil
        didCapturePhotoObservers.invokeEach{$0(op.photo, op.error)}
    }
    
    func updateOutputOrientation(for orientation: UIDeviceOrientation) {
        var result: AVCaptureVideoOrientation = .portrait
        switch orientation {
        case .faceDown, .faceUp, .unknown: return
        case .portrait: result = .portrait
        case .portraitUpsideDown: result = .portraitUpsideDown
        case .landscapeLeft: result = .landscapeRight
        case .landscapeRight: result = .landscapeLeft
        }
        photoOutput.connections
            .filter{$0.isVideoOrientationSupported}
            .forEach{$0.videoOrientation = result}
    }

}

class CameraController {
    class func cameraControllers() throws -> [CameraController] {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        return try session.devices.map{try CameraController(captureDevice: $0)}
    }
    
    let captureDevice: AVCaptureDevice
    let deviceInput: AVCaptureDeviceInput
    var position: AVCaptureDevice.Position {
        return captureDevice.position
    }
    var hasFlash: Bool {
        return captureDevice.hasFlash
    }
    
    private init(captureDevice: AVCaptureDevice) throws {
        self.captureDevice = captureDevice
        deviceInput = try AVCaptureDeviceInput(device: captureDevice)
    }
}

class PrepareCaptureSessionOperation: Operation {
    private(set) var error: Error?
    private(set) var captureSessionController: CaptureSessionController?
    let initialCameraPosition: AVCaptureDevice.Position

    init(initialCameraPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.back) {
        self.initialCameraPosition = initialCameraPosition
    }
    
    override func main() {
        guard !isCancelled else {return}
        do {
            prepareSession(with: try CameraController.cameraControllers())
        } catch let error {
            self.error = error
            logger.error("Cannot prepare session, error: \(error)")
            return
        }
    }
    
    private func prepareSession(with cameras: [CameraController]) {
        guard !cameras.isEmpty else {return}
        let session  = AVCaptureSession()
        
        session.beginConfiguration()
        let camera = cameras.first{$0.position == initialCameraPosition} ?? cameras[0]
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddInput(camera.deviceInput) && session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            return
        }
        session.sessionPreset = .photo
        session.addInput(camera.deviceInput)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        captureSessionController = CaptureSessionController(captureSession: session, photoOutput: photoOutput, cameraControllers: cameras)
    }
}

class OutputOrientation {
    private(set) var currentOrientaion: AVCaptureVideoOrientation = .portrait
    
    func updateVideoOrientation(for orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .faceDown, .faceUp, .unknown: break
        case .portrait: currentOrientaion = .portrait
        case .portraitUpsideDown: currentOrientaion = .portraitUpsideDown
        case .landscapeLeft: currentOrientaion = .landscapeRight
        case .landscapeRight: currentOrientaion = .landscapeLeft
        }
        return currentOrientaion
    }
}
