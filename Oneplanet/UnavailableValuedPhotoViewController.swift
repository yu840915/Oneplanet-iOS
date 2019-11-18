//
//  UnavailableValuedPhotoViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/6.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ValuedPhotoSuspensionInformationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var okButton: UIButton!
    var dismissAction: (()->())?
    var quota: ValuedPostQuota!
    private var refreshClock: UpdateClock!
    private var cooldownTimeFormatter: PostCooldownTimeFormatter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cooldownTimeFormatter = PostCooldownTimeFormatter()
        localizeContents()
        refreshClock = UpdateClock(onTick: {[weak self] in
            self?.updateTimerLabel()
        })
    }
    
    func localizeContents() {
        titleLabel.text = Localized.uploadPopUp.postSuspended
        bulletTextView1.text = Localized.uploadPopUp.cantUploadBullet
        okButton.setTitle(Localized.phrases.iGetIt, for: .normal)
    }

    func updateTimerLabel() {
        guard let cap = quota.lastState else {
            timerLabel.text = "–"
            return
        }
        var dateStr = ""
        if cap.isFull {
            dateStr = Localized.phrases.noRoomForPhoto
        } else if let date = cap.nextChargeDate {
            dateStr = cooldownTimeFormatter.string(for: date)
        }
        timerLabel.text = String(format: Localized.uploadPopUp.cooldownTime, dateStr)
    }

    @IBAction func next(_ sender: Any) {
        if dismissAction != nil {
            dismissAction?()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

}
