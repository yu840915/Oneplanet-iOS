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
    var product: Product! = Product()
    
    var pageViewController: UIPageViewController!
    override func viewDidLoad() {
        super.viewDidLoad()
        showGemPicker()
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
        
    }
    
    func showGreenGemPopUp() {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = UnlockWithGreenGemPopUpConfiguration(productName: product.name)
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
            picker.productName = product.name
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
            vc.configuration = UnlockWithBlueGemPopUpConfiguration(productName: product.name, formattedPrice: "$1.99")
            vc.mainAction = {
                self?.unlock(with: .blueGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: animated, completion: nil)
    }
    
    func showPurpleGemPopUp(animated: Bool) {
        let product = self.product!
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = UnlockWithPurpleGemPopUpConfiguration(productName: product.name)
            vc.mainAction = {
                self?.unlock(with: .purpleGem)
            }
        }
        pageViewController.setViewControllers([container], direction: .forward, animated: animated, completion: nil)
    }
    
    func showUnlockSucceededAlert() {
        let alert = UIAlertController(title: String(format: Localized.messageFormats.unlockSucceeded, product.name), message: Localized.messages.unlockSucceeded, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: { (_) in
            self.dismiss(animated: false, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showInsufficientGemPopUp() {
        let container = prepareActionPopUp{[weak self] vc in
            vc.configuration = InsufficientBlueGemToUnlockPopUpConfiguration(formattedPrice: "$1.99")
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
}

extension UnlockFlowViewController {
    struct StoryboardID {
        static let actionPopUpEntry = "GemActionPopUpEntry"
        static let pickerEntry = "GemPickerEntry"
    }
}

class Product {
    let name = "T-Shirt"
}
