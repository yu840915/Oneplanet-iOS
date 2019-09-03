//
//  PostSubmissionViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/20.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostSubmissionViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var postDraft: PostDraft!
    var submitOperation: SubmitPostOperation!
    var didPublish: (()->())?
    var didFail: ((Error?)->())?
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let op = SubmitPostOperation(draft: postDraft, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSubmitPostDraft()
            }
        }
        submitOperation = op
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        submitOperation.start()
    }

    func didSubmitPostDraft() {
        let op = submitOperation!
        submitOperation = nil
        if op.success == true {
            dismiss(animated: false) {[didPublish] in
                didPublish?()
            }
        } else {
            let error = op.error
            dismiss(animated: false) {[didFail] in
                didFail?(error)
            }
        }
    }

}
