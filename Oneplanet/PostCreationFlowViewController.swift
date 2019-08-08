//
//  PostCreationFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/7.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostCreationFlowViewController: UIViewController, UserSessionDepending {

    var postDraft: PostDraft!
    var userSession: UserSession!
    var authorizationOperation: AskForCameraAndLibraryAuthorizationOperation?
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.darkGray.configure(navigationController!.navigationBar)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nextStep()
    }
    
    func nextStep() {
        if postDraft.images.isEmpty {
            askForPermissions()
        } else {
            //show editor
        }
    }
    
    private func askForPermissions() {
        let op = AskForCameraAndLibraryAuthorizationOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.checkPermissions()
            }
        }
        authorizationOperation = op
        op.start()
    }
    
    private func checkPermissions() {
        var canProceed = false
        if AskForCameraAuthorizationOperation.authorizationStatus == .authorized {
            canProceed = true
        }
        if AskForPhotoLibraryAuthorizationOperation.authorizationStatus == .authorized {
            canProceed = true
        }
        if canProceed {
            performSegue(withIdentifier: SegueID.showPhotoPicker, sender: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = segue.destination as? PostPhotoPickingFlowViewController {
            vc.onPickingImage = {[weak self] image in
                self?.showPostEditor(with: image)
            }
        }
    }
    
}

private extension PostCreationFlowViewController {
    func showPostEditor(with image: UIImage) {
        postDraft.images.append(ImageAttachment(image: image))
        let vc = PostEditorViewController.fromDefaultStoryboard()
        vc.userSession = userSession
        vc.postDraft = postDraft
        navigationController!.pushViewController(vc, animated: true)
    }
}

extension PostCreationFlowViewController {
    struct SegueID {
        static let showPhotoPicker = "showPhotoPicker"
    }
}
