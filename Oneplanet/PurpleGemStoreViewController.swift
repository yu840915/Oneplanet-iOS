//
//  PurpleGemStoreViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PurpleGemStoreViewController: UIViewController, UserSessionDepending {

    class func entryPoint() -> PopUpContainerViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateViewController(withIdentifier: "PurpleGemPopUpEntry") as! PopUpContainerViewController
    }
    
    var userSession: UserSession!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    
    @IBOutlet weak var productListHeight: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        if let plans = IAPTransactionProcessor.shared.prefetchedProducts.rubyProducts {
            productListHeight.constant = CGFloat(plans.count * 50 + 2)
        }
    }
    
    private func localizeTitles() {
        nameLabel.text = Localized.titles.purpleGem
        usageLabel.text = Localized.gemStonePopUp.purpleGemUsage
        bulletTextView1.text = Localized.gemStonePopUp.purpleGemBullet1
        prepareActionBullet()
    }

    private func prepareActionBullet() {
        let text = String(format: Localized.gemStonePopUp.purpleGemBullet2, Localized.titles.blueGem)
        let linkRange = (text as NSString).range(of: Localized.titles.blueGem)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        attrStr.addAttributes([.link : DeepLinks.blueGemPopUp, .font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: linkRange)
        bulletTextView2.delegate = self
        bulletTextView2.attributedText = attrStr
        bulletTextView2.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? UserSessionDepending {
            vc.userSession = userSession
        }
    }

}

extension PurpleGemStoreViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.dismiss(animated: true, completion: {
                router.handle(URL)
            })
        }
        return false
    }
}
