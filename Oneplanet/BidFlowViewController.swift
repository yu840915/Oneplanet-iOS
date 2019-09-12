//
//  BidFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BidFlowViewController: UIViewController, UserSessionDepending {
    var userSession: UserSession!
    var product: ProductOverview!
    var bidProcess: ProductBidProcess!
    private var bidOperation: BidProductOperation?

    var pageViewController: UIPageViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        if userSession.wallet.purpleGem.total > 0 {
            showPurpleGemPopUp(animated: false)
        } else if userSession.wallet.blueGem.total > 0 {
            showBlueGemPopUp()
        } else {
            showInsufficientGemPopUp()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UIPageViewController {
            pageViewController = vc
        }
    }
}

extension BidFlowViewController {
    func cancelAndExit() {
        dismiss(animated: false, completion: nil)
    }
    
    func bid(with gem: Currency) {
        guard bidProcess.isInitialized && !bidProcess.isEnded else {
            showTimeOutAlert()
            return
        }
        guard bidOperation == nil else {
            return
        }
        let loading = FullscreenLoadingViewController.fromDefaultStoryboard()
        present(loading, animated: false, completion: nil)
        let op = BidProductOperation(product: product, session: userSession, currency: gem)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {[weak self] in
                self?.didBid()
            }
        }
        bidOperation = op
        op.start()
    }
    
    func didBid() {
        presentedViewController?.dismiss(animated: false, completion: nil)
        let op = bidOperation!
        bidOperation = nil
        if op.success == true {
            if op.currency == .blueGem {
                userSession.wallet.setNeedsUpdateBlueGem()
            } else {
                userSession.wallet.setNeedsUpdatePurpleGem()
            }
            dismiss(animated: false, completion: nil)
        } else if let error = op.error {
            showFailureAlert(error)
        }
    }
    
    func showTimeOutAlert() {
        let alert = UIAlertController(title: Localized.messages.bidTooLate, message: Localized.messages.gemUnchanged, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: { (_) in
            self.cancelAndExit()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showFailureAlert(_ error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.phrases.tryAgain, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showBlueGemPopUp() {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            let iap = IAPTransactionProcessor.shared.blueGemRelatedProducts.bidProduct!
            let price = IAPTransactionProcessor.shared.blueGemRelatedProducts.priceFormatter!.string(for: iap.price)!
            vc.configuration =
                BidWithBlueGemPopUpConfiguration(productName: product.displayName, formattedPrice: price)
            vc.mainAction = {
                self?.bid(with: .blueGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func showPurpleGemPopUp(animated: Bool) {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration =
                BidWithPurpleGemPopUpConfiguration(productName: product.displayName)
            vc.mainAction = {
                self?.bid(with: .purpleGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func prepareActionPopUp(_ setUp: @escaping (GemActionPopUpViewController)->()) -> PopUpContainerViewController {
        let container = storyboard?.instantiateViewController(withIdentifier: StoryboardID.actionPopUpEntry) as! PopUpContainerViewController
        container.isDismissTapOn = false
        container.contentViewControllerSetUpBlock = {[weak self] vc in
            let popUp = vc as! GemActionPopUpViewController
            popUp.cancelAction = {
                self?.cancelAndExit()
            }
            setUp(popUp)
        }
        return container
    }

    func showBidSucceededAlert() {
        let alert = UIAlertController(title: String(format: Localized.messageFormats.bidSucceeded, product.displayName), message: Localized.messages.bidSucceeded, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: { (_) in
            self.dismiss(animated: false, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showInsufficientGemPopUp() {
        let container = prepareActionPopUp{[weak self] vc in
            let iap = IAPTransactionProcessor.shared.blueGemRelatedProducts.bidProduct!
            let price = IAPTransactionProcessor.shared.blueGemRelatedProducts.priceFormatter!.string(for: iap.price)!
            vc.configuration = InsufficientBlueGemToBidPopUpConfiguration(formattedPrice: price)
            vc.mainAction = {
                self?.goToCreatePost()
            }
            vc.cancelAction = {
                self?.cancelAndExit()
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func showBidTooLatePopUp() {
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration =
                BidTooLateConfiguration()
            vc.mainAction = {
                self?.cancelAndExit()
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func goToCreatePost() {
        dismiss(animated: true) {
            router.handle(DeepLinks.postEditor)
        }
    }
}

extension BidFlowViewController {
    struct StoryboardID {
        static let actionPopUpEntry = "GemActionPopUpEntry"
        static let pickerEntry = "GemPickerEntry"
    }
}
