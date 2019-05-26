//
//  CharacterPickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class CharacterPickerViewController: UIViewController {
    @IBOutlet weak var nicknameRuleLabel: UILabel!
    @IBOutlet weak var nameFieldView: InputFieldView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var colorPromptLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.navigationBar.barStyle = .black
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        
    }

    private func localizeTitles() {
        nameFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.nickname, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        nicknameRuleLabel.text = Localized.phrases.nicknameRule
        doneButton.setTitle(Localized.titles.ok, for: .normal)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}
