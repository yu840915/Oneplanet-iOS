//
//  BlueGemPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class BlueGemPopUpViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var bulletTextView3: UITextView!
    @IBOutlet weak var goButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        nameLabel.text = Localized.titles.blueGem
        usageLabel.text = Localized.gemStonePopUp.blueGemUsage
        bulletTextView1.text = Localized.gemStonePopUp.blueGemBullet1
        bulletTextView2.text = String(format: Localized.gemStonePopUp.blueGemBullet2, "$1.99")
        prepareGoButton()
        prepareActionBullet()
    }
    
    private func prepareGoButton() {
        let text = String(format: Localized.gemStonePopUp.blueGemAction, Localized.feature.life)
        let range = (text as NSString).range(of: Localized.feature.life)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 14), .foregroundColor: ColorPalette.defaultText])
        attrStr.addAttributes([.font: UIFont.systemFont(ofSize: 14, weight: .semibold)], range: range)
        goButton.setAttributedTitle(attrStr, for: .normal)
    }
    
    private func prepareActionBullet() {
        let text = String(format: Localized.gemStonePopUp.blueGemBullet3, Localized.titles.purpleGem)
        let linkRange = (text as NSString).range(of: Localized.titles.purpleGem)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        attrStr.addAttributes([.link : DeepLinks.purpleGemPopUp, .font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: linkRange)
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
            router.handle(DeepLinks.liveTab)
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
