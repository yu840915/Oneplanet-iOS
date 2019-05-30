//
//  PromoPopUpFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PromoPopUpFlowViewController: UIViewController, UserSessionDepending {
    var userSession: UserSession!
    var promoPageList: PromotionPageList?

    @IBOutlet weak var processingContainerView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorView: UIStackView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    fileprivate(set) var promoPages: [PromotionPage] = []
    fileprivate var getPageListOperaion: GetPromotionPageListOperation?
    fileprivate var appearanceAction: (()->())?
    fileprivate var isViewVisible = false

    override func viewDidLoad() {
        super.viewDidLoad()
        retryButton.setTitle(Localized.phrases.tryAgain, for: .normal)
        if let list = promoPageList {
            promoPages = list.pages
            showPromotionPageIfVisible()
        } else {
            getPromotionPageList()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        appearanceAction?()
        appearanceAction = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
    }

    @IBAction func exit(_ sender: Any) {
        getPageListOperaion?.cancel()
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func retry(_ sender: Any) {
        getPromotionPageList()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PromoPopUpViewController {
            vc.page = (sender as! PromotionPage)
            vc.dismissAction = {[weak self] in
                self?.dismissCurrentAndShowNextIfAvailable()
            }
            vc.linkHandler = {[weak self] url in
                return self?.handleLinkIfCapable(url) ?? false
            }
        }
    }

}

fileprivate extension PromoPopUpFlowViewController {
    func getPromotionPageList() {
        guard getPageListOperaion == nil else { return }
        processingContainerView.isHidden = false
        errorView.isHidden = true
        loadingIndicator.startAnimating()
        let op = GetPromotionPageListOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetPromotionPageList()
            }
        }
        getPageListOperaion = op
        op.start()
    }
    
    func didGetPromotionPageList() {
        loadingIndicator.stopAnimating()
        let op = getPageListOperaion!
        getPageListOperaion = nil
        if let list = op.list {
            promoPageList = list
            promoPages = list.pages
            showPromotionPageIfVisible()
        } else {
            errorView.isHidden = false
            errorLabel.text = op.error?.localizedDescription ?? "Unknown error"
        }
    }
    
    func showPromotionPageIfVisible() {
        if promoPages.isEmpty {
            errorView.isHidden = false
            retryButton.isHidden = true
            errorLabel.text = Localized.emptyMessages.promoPopups
        } else {
            processingContainerView.isHidden = false
            if isViewVisible {
                popAndShowPromotionPage()
            } else {
                appearanceAction = {[weak self] in
                    self?.popAndShowPromotionPage()
                }
            }
        }
    }
    
    func popAndShowPromotionPage() {
        performSegue(withIdentifier: "showPopUp", sender: promoPages.removeFirst())
    }
    
    func dismissCurrentAndShowNextIfAvailable() {
        if promoPages.isEmpty {
            presentingViewController!.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true) {[weak self] in
                self?.popAndShowPromotionPage()
            }
        }
    }
    
    func handleLinkIfCapable(_ url: URL) -> Bool {
        if !router.canHandle(url) {
            return false
        }
        presentingViewController!.dismiss(animated: true) {
            router.handle(url)
        }
        return true
    }
}
