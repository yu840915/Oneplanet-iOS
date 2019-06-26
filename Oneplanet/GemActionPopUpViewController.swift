//
//  GemActionPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class GemActionPopUpViewController: UIViewController {
    var mainAction: (()->())?
    var cancelAction: (()->())?
    var configuration: GemActionPopUpConfiguration!

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleTextView: UITextView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subtitleTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
        iconImageView.image = configuration.icon
        titleLabel.attributedText = configuration.attributedTitle
        subtitleTextView.attributedText = configuration.attributedSubtitle
        actionButton.setTitle(configuration.actionTitle, for: .normal)
        cancelButton.setTitle(configuration.cancelTitle, for: .normal)
        cancelButton.isHidden = !configuration.shouldShowCancel
    }
    
    private func handleLink(_ url: URL) {
        dismiss(animated: true) {
            router.handle(url)
        }
    }
    
}

extension GemActionPopUpViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        OperationQueue.main.addOperation {
            self.handleLink(URL)
        }
        return false
    }
}

