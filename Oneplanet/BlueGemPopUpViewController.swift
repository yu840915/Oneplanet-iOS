//
//  BlueGemPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BlueGemPopUpViewController: UIViewController {
    
    class func entryPoint() -> PopUpContainerViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateViewController(withIdentifier: "BlueGemPopUpEntry") as! PopUpContainerViewController
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var goButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        IAPTransactionProcessor.shared.prefetchedProducts.initializeIfNeeded()
        localizeTitles()
    }
    
    private func localizeTitles() {
        nameLabel.text = Localized.titles.blueGem
        usageLabel.text = Localized.gemStonePopUp.blueGemUsage
        var price = ""
        if let prodcut = IAPTransactionProcessor.shared.prefetchedProducts.unlockProduct,
            let formatter = IAPTransactionProcessor.shared.prefetchedProducts.priceFormatter {
            price = formatter.string(for: prodcut.price) ?? ""
        }
        bulletTextView1.font = UIFont.systemFont(ofSize: 12)
        bulletTextView2.font = UIFont.systemFont(ofSize: 12)
        bulletTextView1.text = String(format: Localized.gemStonePopUp.blueGemBullet1, Localized.titles.blueGem, price)
        bulletTextView2.text = String(format: Localized.gemStonePopUp.blueGemBullet2, Localized.titles.blueGem)
        goButton.setTitle(Localized.gemStonePopUp.blueGemAction, for: .normal)
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func invokeGoAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            router.handle(DeepLinks.postEditor)
        })
    }
}

extension BlueGemPopUpViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.dismiss(animated: true, completion: {
                router.handle(URL)
            })
        }
        return false
    }
}
