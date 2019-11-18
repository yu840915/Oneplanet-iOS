//
//  ReportThankyouViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ReportThankyouViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var doneButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        doneButtonItem.title = Localized.titles.done
        
        titleLabel.text = Localized.messages.thankYouForReportingUser
        let text = String(format: Localized.messageFormats.thankYouForReportUser, Localized.titles.tos)
        let linkRange = (text as NSString).range(of: Localized.titles.tos)
        let attrStr = NSMutableAttributedString(string: text, attributes: [.font:  UIFont.systemFont(ofSize: 14)])
        attrStr.addAttributes([.link : ServiceURLs.terms, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)], range: linkRange)
        detailTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
        detailTextView.attributedText = attrStr
    }

    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
