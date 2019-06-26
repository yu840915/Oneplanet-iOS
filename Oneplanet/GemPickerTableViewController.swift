//
//  GemPickerTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class GemPickerTableViewController: UITableViewController {
    
    var didSelectGem:((Currency)->())?
    var cancelAction: (()->())?
    var productName: String = ""
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var blueGemLabel: UILabel!
    @IBOutlet weak var purpleGemLabel: UILabel!
    let rows: [Row] = [.blueGem, .purpleGem]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        subtitleLabel.text = String(format: Localized.messageFormats.unlockOptionPrompt, Localized.titles.blueGem, Localized.titles.purpleGem)
        cancelButton.setTitle(Localized.titles.cancel, for: .normal)
        blueGemLabel.text = Localized.titles.blueGem
        purpleGemLabel.text = Localized.titles.purpleGem
        prepareAttributedTitle()
    }
    
    private func prepareAttributedTitle() {
        let text = String(format: Localized.messageFormats.unlockWithGem, productName)
        let range = (text as NSString).range(of: productName)
        let result = NSMutableAttributedString(string: text, attributes: [.foregroundColor: ColorPalette.defaultText, .font: UIFont.systemFont(ofSize: 17)])
        result.addAttributes([
            .foregroundColor: ColorPalette.defaultText,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)],
                             range: range)
        titleLabel.attributedText = result
    }
    
    @IBAction func cancel(_ sender: Any) {
        if let action = cancelAction {
            action()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch rows[indexPath.row] {
        case .blueGem: didSelectGem?(.blueGem)
        case .purpleGem: didSelectGem?(.purpleGem)
        }
    }

}

extension GemPickerTableViewController {
    enum Row {
        case blueGem
        case purpleGem
    }
}

enum Currency {
    case blueGem
    case purpleGem
    case greenGem
}
