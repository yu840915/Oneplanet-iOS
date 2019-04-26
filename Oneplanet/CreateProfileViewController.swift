//
//  CreateProfileViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/27.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class CreateProfileViewController: UIViewController {

    @IBOutlet weak var nameFieldView: InputFieldView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var addAvatarButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var addAvatarView: UIStackView!
    @IBOutlet weak var avatarAddedLabel: UILabel!
    @IBOutlet weak var changeAvatarButton: UIButton!
    @IBOutlet weak var addAvatarPromptLabel: UILabel!
    
    @IBOutlet weak var changeAvatarView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        avatarImageView.layer.cornerRadius = 40.0
        localizeTitles()
    }
    
    private func localizeTitles() {
        nameFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.nickname, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        greetingLabel.text = Localized.phrase.newUserGreeting
        addAvatarButton.setTitle(Localized.phrase.addAvatar, for: .normal)
        addAvatarPromptLabel.text = Localized.messages.addAvatarPrompt
        changeAvatarButton.setTitle(Localized.phrase.changeAvatar, for: .normal)
        avatarAddedLabel.text = Localized.phrase.avatarAdded
        nextButton.setTitle(Localized.titles.next, for: .normal)
    }

    @IBAction func startImagePickingFlow(_ sender: UIButton) {
        showPickerSelectionSheet()
    }
    
    private func showPickerSelectionSheet() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: Localized.phrase.takePhoto, style: .default, handler: { (_) in
            
        }))
        sheet.addAction(UIAlertAction(title: Localized.phrase.fromLibrary, style: .default, handler: { (_) in
            
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
}
