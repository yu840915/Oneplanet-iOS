//
//  PostCreationPortalViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostCreationPortalViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    @IBOutlet weak var controlContainer: UIStackView!
    @IBOutlet weak var valuedPhotoLabel: UILabel!
    @IBOutlet weak var valuedPhotoCapacityLabel: UILabel!
    @IBOutlet weak var freePhotoLabel: UILabel!
    var startPostCreationFlow: ((PostDraft)->())?
    private var capacity: PhotoUploadCapacity? = PhotoUploadCapacity()
    private var refreshClock: UpdateClock!
    private var cooldownTimeFormatter: PostCooldownTimeFormatter!

    override func viewDidLoad() {
        super.viewDidLoad()
        cooldownTimeFormatter = PostCooldownTimeFormatter()
        valuedPhotoLabel.text = Localized.phrases.uploadValuedPhoto
        freePhotoLabel.text = Localized.phrases.uploadFreePhoto
        refreshClock = UpdateClock(onTick: {[weak self] in
            self?.updatePhotoCapacityLabel()
        })
    }
    
    func updatePhotoCapacityLabel() {
        guard let cap = capacity else {
            valuedPhotoCapacityLabel.text = "–"
            return
        }
        let formatter = SharedNumberFormatters.integer
        valuedPhotoCapacityLabel.text = String(format: Localized.phraseFormats.remainingUploads, formatter.string(for: cap.available)!, formatter.string(for: cap.total)!, cooldownTimeFormatter.string(for: cap.nextRefillTime)!)
    }
    
    @IBAction func selectValuedPhoto(_ sender: Any) {
        performSegue(withIdentifier: SegueID.showValuedPhotoInfo, sender: nil)
//        if Preferences.shouldHideValuedPhotoInfo.value == true {
//            //repor
//        } else {
//            performSegue(withIdentifier: SegueID.showValuedPhotoInfo, sender: nil)
//        }
    }
    
    
    @IBAction func selectFreePhoto(_ sender: Any) {
        if Preferences.shouldHideFreePhotoInfo.value == true {
            
        } else {
            performSegue(withIdentifier: SegueID.showFreePhotoInfo, sender: nil)
        }
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contaier = segue.destination as? PopUpContainerViewController {
            if segue.identifier == SegueID.showCantUploadInfo {
                contaier.isDismissTapOn = false
            } else {
                contaier.dismissAction = {[weak self] in
                    self?.dismissPopUp()
                }
            }
            contaier.contentViewControllerSetUpBlock = {[weak self] vc in
                self?.preparePopUp(vc)
            }
        }
    }
    
    private func preparePopUp(_ popUp: UIViewController) {
        controlContainer.isHidden = true
        if let vc = popUp as? UserSessionDepending {
            vc.userSession = userSession
        }
        if let vc = popUp as? ValuedPhotoInformationPopUpViewController {
            prepareValuedPhotoPopUp(vc)
        } else if let vc = popUp as? FreePhotoInformationPopUpViewController {
            prepareFreePhotoPopUp(vc)
        } else if let vc = popUp as? ValuedPhotoSuspensionInformationViewController {
            prepareSuspensionPopUp(vc)
        }
    }
    
    func prepareValuedPhotoPopUp(_ popUp: ValuedPhotoInformationPopUpViewController) {
        popUp.handleURL = {[weak self] url in
            self?.exitAndHandle(url)
        }
        popUp.nextAction = {[weak self] in
            self?.startPostCreationFlow?(PostDraft(isValued: true))
        }
        popUp.dismissAction = {[weak self] in
            self?.dismissPopUp()
        }
    }
    
    func exitAndHandle(_ url: URL) {
        let presenter = presentingViewController ?? self
        presenter.dismiss(animated: true) {
            OperationQueue.main.addOperation {
                router.handle(url)
            }
        }
    }
    
    func prepareFreePhotoPopUp(_ popUp: FreePhotoInformationPopUpViewController) {
        popUp.handleURL = {[weak self] url in
            self?.exitAndHandle(url)
        }
        popUp.nextAction = {[weak self] in
            self?.startPostCreationFlow?(PostDraft(isValued: false))
        }
        popUp.dismissAction = {[weak self] in
            self?.dismissPopUp()
        }
    }
    
    func prepareSuspensionPopUp(_ popUp: ValuedPhotoSuspensionInformationViewController) {
        popUp.capacity = capacity
        popUp.dismissAction = {[weak self] in
            self?.dismissPopUp()
        }
    }
    
    func dismissPopUp() {
        controlContainer.isHidden = false
        dismiss(animated: true, completion: {})
    }
}

extension PostCreationPortalViewController {
    struct SegueID {
        static let showValuedPhotoInfo = "showValuedPhotoInfo"
        static let showFreePhotoInfo = "showFreePhotoInfo"
        static let showCantUploadInfo = "showCantUploadInfo"
    }
}

class PhotoUploadCapacity {
    let available: Int = 9
    let total: Int = 10
    let nextRefillTime: Date? = Date(timeIntervalSinceNow: .hour)
}

class PostCooldownTimeFormatter: Formatter {
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        return TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
    }()
    
    override func string(for obj: Any?) -> String? {
        if obj == nil {
            return Localized.phrases.noRoomForPhoto
        }
        if let date = obj as? Date {
            return string(for: date)
        }
        return nil
    }
    
    func string(for date: Date) -> String {
        let comp = TimeIntervalComponents(extractor.extract(from: date.timeIntervalSinceNow))
        var val = ""
        if comp.hours > 0 {
            val += SharedNumberFormatters.clockComponent.string(for: comp.hours)!
            val += ":"
        }
        val += SharedNumberFormatters.clockComponent.string(for: comp.minutes)!
        val += ":"
        val += SharedNumberFormatters.clockComponent.string(for: comp.seconds)!
        return val
    }
}
