//
//  PickImageOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/24.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks
import AVFoundation

class PickImageOperation: SimpleAsynchronousOperation {
    private(set) var image: UIImage?
    private(set) var error: Error?
    private(set) weak var presenter: UIViewController!
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    fileprivate func fail(with error: Error) {
        self.error = error
        finish()
    }
    
    fileprivate func finishPickingImage(_ image: UIImage) {
        self.image = image
        finish()
    }
}

class PickCameraImageOperation: PickImageOperation {
    let initialCameraPosition: AVCaptureDevice.Position
    private var authorizationOperation: AskForCameraAuthorizationOperation?
    private var pickerFlow: CameraImagePickerViewController?
    init(initialCameraPosition: AVCaptureDevice.Position = .back, presenter: UIViewController) {
        self.initialCameraPosition = initialCameraPosition
        super.init(presenter: presenter)
    }
    override func main() {
        checkPermission()
    }
    
    private func checkPermission() {
        switch AskForCameraAuthorizationOperation.authorizationStatus {
        case .notDetermined: askForPermissin()
        case .authorized: prepareCameraFlow()
        case .denied: fail(with: MissingInputPermissionError(Localized.errors.noCameraAccess))
        }
    }
    
    private func askForPermissin() {
        let op = AskForCameraAuthorizationOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.checkPermission()
            }
        }
        authorizationOperation = op
        op.start()
    }
    
    private func prepareCameraFlow() {
        let op = PrepareCaptureSessionOperation(initialCameraPosition: initialCameraPosition)
        op.start()
        if let session = op.captureSessionController {
            showCameraFlow(with: session)
        } else if let error = op.error {
            fail(with: error)
        } else {
            finish()
        }
    }
    
    private func showCameraFlow(with session: CaptureSessionController) {
        let nav = CameraImagePickerViewController.entryPoint()
        let vc = nav.viewControllers.first as! CameraImagePickerViewController
        vc.captureSessionController = session
        vc.onPickingImage = {[weak self] photo in
            self?.handlePickedImage(photo)
        }
        vc.onCancel = {[weak self] in
            self?.handleUserCancel()
        }
        presenter.present(nav, animated: true, completion: nil)
    }
    
    private func handlePickedImage(_ image: UIImage) {
        dismissCameraFlow()
        finishPickingImage(image)
    }
    
    private func handleUserCancel() {
        dismissCameraFlow()
        finish()
    }
    
    private func dismissCameraFlow() {
        let vc = presenter ?? pickerFlow
        vc?.dismiss(animated: true, completion: nil)
    }
}

class PickLibraryImageOperation: PickImageOperation {
    private var authorizationOperation: AskForPhotoLibraryAuthorizationOperation?
    private var pickerFlow: LibraryImagePickerViewController?
    
    override func main() {
        checkPermission()
    }
    
    private func checkPermission() {
        switch AskForPhotoLibraryAuthorizationOperation.authorizationStatus {
        case .notDetermined: askForPermissin()
        case .authorized: prepareLibraryFlow()
        case .denied: fail(with: MissingInputPermissionError(Localized.errors.noLibraryAccess))
        }
    }
    
    private func askForPermissin() {
        let op = AskForPhotoLibraryAuthorizationOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.checkPermission()
            }
        }
        authorizationOperation = op
        op.start()
    }
    
    private func prepareLibraryFlow() {
        let nav = LibraryImagePickerViewController.entryPoint()
        let vc = nav.viewControllers.first as! LibraryImagePickerViewController
        vc.onPickingImage = {[weak self] image in
            self?.handlePickedImage(image)
        }
        vc.onCancel = {[weak self] in
            self?.handleUserCancel()
        }
        presenter.present(nav, animated: true, completion: nil)
        pickerFlow = vc
    }
    
    private func handlePickedImage(_ image: UIImage) {
        dismissPickerFlow()
        finishPickingImage(image)
    }
    
    private func handleUserCancel() {
        dismissPickerFlow()
        finish()
    }

    private func dismissPickerFlow() {
        let vc = presenter ?? pickerFlow
        vc?.dismiss(animated: true, completion: nil)
    }
}

class MissingInputPermissionError: GenericAppError {
}
