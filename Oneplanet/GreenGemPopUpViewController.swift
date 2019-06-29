//
//  GreenGemPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class GreenGemPopUpViewController: UIViewController {

    class func entryPoint() -> PopUpContainerViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateViewController(withIdentifier: "GreenGemPopUpEntry") as! PopUpContainerViewController
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var bulletTextView3: UITextView!
    @IBOutlet weak var bulletTextView4: UITextView!
    @IBOutlet weak var bulletTextView5: UITextView!

    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        nameLabel.text = Localized.titles.greenGem
        usageLabel.text = Localized.gemStonePopUp.greenGemUsage
        bulletTextView1.text = Localized.gemStonePopUp.greenGemBullet1
        bulletTextView2.text = Localized.gemStonePopUp.greenGemBullet2
        bulletTextView4.text = Localized.gemStonePopUp.greenGemBullet4
        prepareGoButton()
        prepareActionBullet()
    }
    
    private func prepareGoButton() {
        let text = String(format: Localized.gemStonePopUp.greenGemAction, Localized.feature.notice)
        let range = (text as NSString).range(of: Localized.feature.notice)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 14), .foregroundColor: ColorPalette.defaultText])
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], range: range)
        goButton.setAttributedTitle(attrStr, for: .normal)
    }
    
    private func prepareActionBullet() {
        let text = String(format: Localized.gemStonePopUp.greenGemBullet3, Localized.feature.events)
        let linkRange = (text as NSString).range(of: Localized.feature.events)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        attrStr.addAttributes([.link : DeepLinks.modalEventsPage, .font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: linkRange)
        bulletTextView3.delegate = self
        bulletTextView3.attributedText = attrStr
        bulletTextView3.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func invokeGoAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            router.handle(DeepLinks.noticeTab)
        })
    }
}

extension GreenGemPopUpViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.dismiss(animated: true, completion: {
                router.handle(URL)
            })
        }
        return false
    }
}
