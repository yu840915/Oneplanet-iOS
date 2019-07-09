//
//  CharacterPickerViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class CharacterPickerViewController: UIViewController, UserSessionDepending {
    var userSession: UserSession!
    var draft: ProfileDraft!
    var didCreateProfile: (()->())?
    
    @IBOutlet weak var alienDescriptionLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var colorPromptLabel: UILabel!
    @IBOutlet weak var colorPickerWidth: NSLayoutConstraint!
    
    @IBOutlet weak var monologueContainer: UIStackView!
    @IBOutlet weak var chatBubble: UIView!
    @IBOutlet weak var monologueLabel: UILabel!
    
    private let monologueItem = MonologueItem()
    private var alienPicker: AlienPickerCollectionViewController!
    private var colorPicker: ColorPickerCollectionViewController!
    private var updateProfileOperation: UpdateProfileOperation? {
        didSet {
            updateViewForRunningOperation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        monologueItem.containerView = monologueContainer
        monologueItem.textLabel = monologueLabel
        chatBubble.layer.cornerRadius = (chatBubble.frame.height / 2)
        localizeTitles()
        colorPickerWidth.constant = CGFloat(CharacterOptions.shared.colors.count * 44)
        updateAlienOptions(withColor: colorPicker.selectedColor!)
        setUpPreselection()
    }

    private func updateViewForRunningOperation() {
        let allowsAction = updateProfileOperation == nil
        [doneButton, leftButton, rightButton].forEach{$0?.isEnabled = allowsAction}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
    }

    private func localizeTitles() {
        title = Localized.phrases.chooseRole
        alienDescriptionLabel.text = Localized.messages.alienDescription
        colorPromptLabel.text = Localized.phrases.chooseColor
        doneButton.setTitle(Localized.titles.ok, for: .normal)
    }
    
    private func updateAlienOptions(withColor color: CharacterColor) {
        alienPicker.characters = CharacterOptions.shared.characterOptions(for: color)
    }
    
    private func setUpPreselection() {
        let characters = CharacterOptions.shared.characterOptions(for: colorPicker.selectedColor!)
        if let character = draft.character,
            let idx = characters.index(of: character) {
            alienPicker.preselectedIndex = idx
        }
    }
    
    @IBAction func submit(_ sender: UIButton) {
        view.endEditing(false)
        if let color = colorPicker.selectedColor {
            draft.character = CharacterOptions.shared.characterOptions(for: color)[alienPicker.selectedIndex]
        }
        showConfirmAlert()
    }
    
    private func showConfirmAlert() {
        let alert = UIAlertController(title: Localized.warningTitles.characterSelection, message: Localized.warnings.characterSelection, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: { (_) in
            self.submitProfile()
        }))
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func submitProfile() {
        guard updateProfileOperation == nil else {
            return
        }
        let op = UpdateProfileOperation(draft: draft, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSubmitProfile()
            }
        }
        updateProfileOperation = op
        op.start()
    }
    
    private func didSubmitProfile() {
        let op = updateProfileOperation!
        updateProfileOperation = nil
        if op.success == true {
            userSession.updateProfile(userSession.profile!.updating(with: draft))
            didCreateProfile?()
        }
        if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    
    @IBAction func pickPrevious(_ sender: UIButton) {
        alienPicker.scrollToPrevious()
    }
    
    @IBAction func pickNext(_ sender: UIButton) {
        alienPicker.scrollToNext()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AlienPickerCollectionViewController {
            vc.monologueItem = monologueItem
            alienPicker = vc
        } else if let vc = segue.destination as? ColorPickerCollectionViewController {
            colorPicker = vc
            vc.colors = CharacterOptions.shared.colors
            vc.selectedColor = draft.character?.color ?? CharacterOptions.shared.colors[0]
            vc.didChangeSelection = {[weak self] color in
                self?.updateAlienOptions(withColor: color)
            }
        }
    }

}

class MonologueItem {
    var isHidden: Bool = true {
        didSet {
            updateAppearance()
        }
    }
    var monologue: String = "" {
        didSet {
            updateTextLabel()
        }
    }
    var textLabel: UILabel? {
        didSet {
            updateTextLabel()
        }
    }
    var containerView: UIView? {
        didSet {
            updateAppearance()
        }
    }
    
    private func updateTextLabel() {
        guard let label = textLabel else {
            return
        }
        label.text = monologue
    }
    private func updateAppearance() {
        guard let view = containerView else {
            return
        }
        view.isHidden = isHidden
    }
}
