//
//  UnlockFlowViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/27.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UnlockFlowViewController: UIViewController, UserSessionDepending {
    var userSession: UserSession!
    var product: ProductOverview!
    var unlockOperation: UnlockProductOperation?
    var unlockWithBlueGemOperation: UnlockWithBlueGemOperation?
    var successHandler: (()->())?
    
    var pageViewController: UIPageViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        if userSession.bidPhaseIndicator.biddingHasStarted {
            showTooLatePopUp(animated: false)
            return
        }
        if userSession.wallet.greenGem.total > 0 {
            showGreenGemPopUp()
        } else if userSession.wallet.blueGem.total > 0 {
            showBlueGemPopUp(animated: false)
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

private extension UnlockFlowViewController {
    func cancelAndExit() {
        dismiss(animated: true, completion: nil)
    }
    
    func unlock(with gemType: Currency) {
        if userSession.bidPhaseIndicator.biddingHasStarted {
            showTooLatePopUp(animated: true)
            return
        }
        guard unlockOperation == nil && unlockWithBlueGemOperation == nil else {
            return
        }
        let loading = FullscreenLoadingViewController.fromDefaultStoryboard()
        present(loading, animated: false, completion: nil)
        if gemType == .blueGem {
            let op = UnlockWithBlueGemOperation(product: product, transactionProcesser: .shared, session: userSession)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.dismisLoading{[weak self] in
                        self?.didUnlockWithBlueGem()
                    }
                }
            }
            unlockWithBlueGemOperation = op
            op.start()
        } else {
            let op = UnlockProductOperation(product: product, session: userSession, currency: gemType)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.dismisLoading{[weak self] in
                        self?.didUnlock()
                    }
                }
            }
            unlockOperation = op
            op.start()
        }
    }
    
    func dismisLoading(completion: @escaping (()->())) {
        if let vc = presentedViewController {
            vc.dismiss(animated: false, completion: completion)
        } else {
            completion()
        }
    }
    
    func didUnlockWithBlueGem() {
        let op = unlockWithBlueGemOperation!
        unlockWithBlueGemOperation = nil
        if op.success == true {
            dismiss(animated: false, completion: successHandler)
        } else if let error = op.error {
            if op.shouldShowCompensationPopUp {
                showTooLatePopUp(animated: true)
            } else if error is InsufficienFundError {
                showInsufficientGemPopUp()
            } else {
                showFailureAlert(error)
            }
        }
    }
    
    func didUnlock() {
        let op = unlockOperation!
        unlockOperation = nil
        if op.success == true {
            switch op.currency {
            case .blueGem: userSession.wallet.setNeedsUpdateBlueGem()
            case .purpleGem: userSession.wallet.setNeedsUpdatePurpleGem()
            case .greenGem: userSession.wallet.setNeedsUpdateGreenGem()
            }
            dismiss(animated: false, completion: successHandler)
        } else if let error = op.error {
            showFailureAlert(error)
        }
    }
    
    func showFailureAlert(_ error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.phrases.tryAgain, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func showGreenGemPopUp() {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = UnlockWithGreenGemPopUpConfiguration(productName: product.displayName)
            vc.mainAction = {
                self?.unlock(with: .greenGem)
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
    
    func showGemPicker() {
        let product = self.product!
        let container = storyboard?.instantiateViewController(withIdentifier: StoryboardID.pickerEntry) as! PopUpContainerViewController
        container.isDismissTapOn = false
        container.contentViewControllerSetUpBlock = {[weak self] vc in
            let picker = vc as! GemPickerTableViewController
            picker.productName = product.displayName
            picker.cancelAction = {
                self?.cancelAndExit()
            }
            picker.didSelectGem = { gem in
                switch gem {
                case .blueGem:
                    self?.showBlueGemPopUp(animated: true)
                case .purpleGem:
                    self?.showPurpleGemPopUp(animated: true)
                default: break
                }
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func showBlueGemPopUp(animated: Bool) {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            let iap = IAPTransactionProcessor.shared.prefetchedProducts.unlockProduct!
            let price = IAPTransactionProcessor.shared.prefetchedProducts.priceFormatter!.string(for: iap.price)!
            vc.configuration = UnlockWithBlueGemPopUpConfiguration(productName: product.displayName, formattedPrice: price)
            vc.mainAction = {
                self?.unlock(with: .blueGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: animated, completion: nil)
    }
    
    func showPurpleGemPopUp(animated: Bool) {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = UnlockWithPurpleGemPopUpConfiguration(productName: product.displayName)
            vc.mainAction = {
                self?.unlock(with: .purpleGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: animated, completion: nil)
    }
    
    func showUnlockSucceededAlert() {
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = UnlockSuccessPopUpConfiguration()
            vc.mainAction = {
                self?.unlock(with: .purpleGem)
            }
            vc.cancelAction = {
                self?.cancelAndExit()
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: true, completion: nil)
    }
    
    func showInsufficientGemPopUp() {
        let container = prepareActionPopUp{[weak self] vc in
            let iap = IAPTransactionProcessor.shared.prefetchedProducts.unlockProduct!
            let price = IAPTransactionProcessor.shared.prefetchedProducts.priceFormatter!.string(for: iap.price)!
            vc.configuration = InsufficientBlueGemToUnlockPopUpConfiguration(formattedPrice: price)
            vc.mainAction = {
                self?.goToCreatePost()
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: false, completion: nil)
    }
    
    func goToCreatePost() {
        dismiss(animated: true) {
            router.handle(DeepLinks.postEditor)
        }
    }
    
    func showTooLatePopUp(animated: Bool) {
        let subtitle = userSession.bidPhaseIndicator.phase == .ended ? Localized.messages.lotClosedDescription : Localized.messages.lotBeingBidDescription
        let container = prepareActionPopUp {[weak self] (vc) in
            let config = UnlockTooLateConfiguration()
            config.subtitle = subtitle
            vc.configuration = config
            vc.mainAction = {
                self?.cancelAndExit()
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: animated, completion: nil)
    }
}

extension UnlockFlowViewController {
    struct StoryboardID {
        static let actionPopUpEntry = "GemActionPopUpEntry"
        static let pickerEntry = "GemPickerEntry"
    }
}
