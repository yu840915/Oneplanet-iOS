//
//  CameraImagePickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/23.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import AVFoundation

class CameraImagePickerViewController: UIViewController {
    @IBOutlet weak var switchButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    var captureSessionController: CaptureSessionController!
    private var eventRegistrations: [Any]?
    @IBOutlet weak var previewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerEvents()
        setUpForPreview()
        updateViewsForCaptureSessionCapabilities()
        updateViewsForCaptureSessionStates()
        updateOutputOrientation()
    }
    
    private func registerEvents() {
        var registrations = [Any]()
        registrations.append(captureSessionController.didCapturePhotoObservers.add({[weak self] (photo, error) in
            OperationQueue.main.addOperation {
                self?.handlePhotoCapture(photo, error: error)
            }
        }))
        registrations.append(NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main, using: {[weak self] (_) in
            self?.updateOutputOrientation()
        }))
        eventRegistrations = registrations
    }
    
    private func setUpForPreview() {
        captureSessionController.previewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(captureSessionController.previewLayer)
        captureSessionController.previewLayer.bounds = previewView.bounds
    }
    
    private func updateOutputOrientation() {
        captureSessionController.updateOutputOrientation(for: UIDevice.current.orientation)
    }
    
    override func viewDidLayoutSubviews() {
        captureSessionController.previewLayer.bounds = previewView.bounds
    }
    
    private func updateViewsForCaptureSessionCapabilities() {
        flashButton.isHidden = !captureSessionController.hasFlash
        switchButton.isHidden = !captureSessionController.canSwitchCamera
    }
    
    private func updateViewsForCaptureSessionStates() {
        flashButton.isSelected = captureSessionController.isFlashOn
    }
    
    private func handlePhotoCapture(_ photo: AVCapturePhoto?, error: Error?) {
        if let photo = photo {
            
        } else if let error = error {
            showAlert(for: error)
        }
    }
    
    private func showAlert(for error: Error) {
        let alert = UIAlertController(title: Localized.errorTitles.cannotCapturePhoto, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func switchCamera(_ sender: UIButton) {
        guard captureSessionController.canSwitchCamera else { return }
        guard let cam = captureSessionController.cameraControllers.first(where: {
            $0 !== captureSessionController.currentCamera
        }) else {return}
        captureSessionController.switchToCamera(cam)
    }
    
    @IBAction func toggleFlash(_ sender: UIButton) {
        captureSessionController.isFlashOn = !captureSessionController.isFlashOn
        updateViewsForCaptureSessionStates()
    }
    
    @IBAction func takePhoto(_ sender: UIButton) {
        captureSessionController.takePhotoIfReady()
    }
}

