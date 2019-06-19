//
//  BiddingTermsViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class BiddingTermsViewController: UIViewController {
    class func entryPoint() -> PopUpContainerViewController {
        return UIStoryboard(name: "SupportingFlows", bundle: nil).instantiateViewController(withIdentifier: "BiddingTermsPopUpEntry") as! PopUpContainerViewController
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var agreeSection: UIStackView!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    var exitAction: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSubmitButton()
        localizeTitles()
    }
    
    @IBAction func exit(_ sender: UIButton) {
        exitAction?()
    }
    
    @IBAction func toggleTermAgreement(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        updateSubmitButton()
    }
    
    @IBAction func submitConsent(_ sender: UIButton) {
        recordConsent()
        exitAction?()
    }
    
    private func recordConsent() {
        
    }
    
    private func updateSubmitButton() {
        submitButton.isEnabled = (!agreeButton.isHidden && agreeButton.isEnabled && agreeButton.isSelected)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? WebViewController {
            vc.request = URLRequest(url: ServiceURLs.biddingTerms)
        }
    }
}

private extension BiddingTermsViewController {
    func localizeTitles() {
        titleLabel.text = Localized.titles.biddingTerms
        submitButton.setTitle(Localized.titles.ok, for: .normal)
        agreeButton.setTitle(Localized.messages.biddingTermsAcceptence, for: .normal)
    }
}

class BiddingFeatureAccessCheckOperation: SimpleAsynchronousOperation {
    let userSession: UserSession
    private(set) var isAccessible = false
    private var popUpController: UIViewController?
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    override func main() {
        let op = FeatureAccessCheckOperation(userSession: userSession)
        op.start()
        guard op.isAccessible else {
            finish()
            return
        }
        if needsConsent {
            showTermsPopup()
        } else {
            isAccessible = true
            finish()
        }
    }
    
    private func showTermsPopup() {
        guard let presenter = FrontViewControllerFinder.findFront() else {
            finish()
            return
        }
        let entryVC = BiddingTermsViewController.entryPoint()
        entryVC.contentViewControllerSetUpBlock = {[weak self] vc in
            self?.setUp(vc as! BiddingTermsViewController)
        }
        presenter.present(entryVC, animated: true, completion: nil)
        popUpController = entryVC
    }
    
    private func setUp(_ controller: BiddingTermsViewController) {
        controller.exitAction = {[weak self] in
            self?.dismissAndCheckConsent()
        }
    }
    
    private func dismissAndCheckConsent() {
        isAccessible = !needsConsent
        popUpController?.dismiss(animated: true, completion: {
            self.finish()
        })
    }
    
    private var needsConsent: Bool = true
}
