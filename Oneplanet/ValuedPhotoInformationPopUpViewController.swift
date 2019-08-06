//
//  ValuedPhotoInformationPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ValuedPhotoInformationPopUpViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    var nextAction: (()->())?
    var handleURL: ((URL)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeContents()
        prepareBullets()
    }
    
    func localizeContents() {
        titleLabel.text = Localized.phrases.uploadValuedPhoto
        okButton.setTitle(Localized.phrases.iGetIt, for: .normal)
        hideButton.setTitle(Localized.phrases.dontShowAgain, for: .normal)
    }
    
    func prepareBullets() {
        bulletTextView1.delegate = self
        bulletTextView2.delegate = self
        bulletTextView1.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
        bulletTextView2.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
        bulletTextView1.attributedText = prepareBullet(with: Localized.uploadPopUp.valuedUploadBullet1)
        bulletTextView2.attributedText = prepareBullet(with: Localized.uploadPopUp.valuedUploadBullet2)
    }
    
    private func prepareBullet(with format: String) -> NSAttributedString {
        let text = String(format: format, Localized.titles.blueGem)
        let linkRange = (text as NSString).range(of: Localized.titles.blueGem)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 12)])
        attrStr.addAttributes([.link : DeepLinks.blueGemPopUp, .font: UIFont.systemFont(ofSize: 12, weight: .semibold)], range: linkRange)
        return attrStr
    }
    
    @IBAction func next(_ sender: Any) {
        Preferences.shouldHideValuedPhotoInfo.value = hideButton.isSelected
        nextAction?()
    }
    
    @IBAction func toggleHide(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }

}

extension ValuedPhotoInformationPopUpViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        handleURL?(URL)
        return false
    }
}
