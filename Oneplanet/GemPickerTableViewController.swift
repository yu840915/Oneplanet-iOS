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
        view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 1))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.frame.height < tableView.contentSize.height {
            view.addConstraint(NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: tableView.contentSize.height))
            view.superview!.setNeedsLayout()
        }
    }
    
    private func localizeTitles() {
        titleLabel.text = Localized.phrases.unlockOptionPrompt
        subtitleLabel.text = Localized.messages.unlockOptionPrompt
        cancelButton.setTitle(Localized.titles.cancel, for: .normal)
        blueGemLabel.text = Localized.titles.blueGem
        purpleGemLabel.text = Localized.titles.purpleGem
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

extension Currency {
    var largeIcon: UIImage {
        switch self {
        case .blueGem: return #imageLiteral(resourceName: "ic_gem80_nor")
        case .purpleGem: return #imageLiteral(resourceName: "ic_coin80_nor")
        case .greenGem: return #imageLiteral(resourceName: "ic_key80_nor")
        }
    }
    
    var displayName: String {
        switch self {
        case .blueGem: return Localized.titles.blueGem
        case .purpleGem: return Localized.titles.purpleGem
        case .greenGem: return Localized.titles.greenGem
        }
    }
}
