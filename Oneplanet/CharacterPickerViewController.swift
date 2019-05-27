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
    
    @IBOutlet weak var nicknameRuleLabel: UILabel!
    @IBOutlet weak var nameFieldView: InputFieldView!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var colorPromptLabel: UILabel!
    @IBOutlet weak var colorPickerWidth: NSLayoutConstraint!
    @IBOutlet weak var closeButtonItem: UIBarButtonItem!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    
    private var alienPicker: AlienPickerCollectionViewController!
    private var colorPicker: ColorPickerCollectionViewController!
    private var updateProfileOperation: UpdateProfileOperation? {
        didSet {
            updateViewForRunningOperation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
        colorPickerWidth.constant = CGFloat(CharacterOptions.shared.colors.count * 44)
        updateAlienOptions(withColor: colorPicker.selectedColor!)
        updateViewsForDraft()
    }
    
    private func updateViewsForDraft() {
        nameFieldView.textField.text = draft.nickname
        doneButton.isEnabled = !draft.nickname.isEmpty
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
        colorPromptLabel.text = Localized.phrases.chooseColor
        nameFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.nickname, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        nicknameRuleLabel.text = Localized.phrases.nicknameRule
        doneButton.setTitle(Localized.titles.ok, for: .normal)
        closeButtonItem.title = Localized.titles.cancel
    }
    
    private func updateAlienOptions(withColor color: CharacterColor) {
        alienPicker.characters = CharacterOptions.shared.characterOptions(for: color)
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    @IBAction func submit(_ sender: UIButton) {
        view.endEditing(false)
        draft.nickname = nameFieldView.textField.text ?? ""
        if let color = colorPicker.selectedColor {
            draft.character = CharacterOptions.shared.characterOptions(for: color)[alienPicker.selectedIndex]
        }
        showConfirmAlert()
    }
    
    private func showConfirmAlert() {
        let alert = UIAlertController(title: Localized.warningTitles.characterSelection, message: Localized.warnings.characterSelection, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .default, handler: { (_) in
            
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
        resetErrorDisplay()
        if op.success == true {
            userSession.updateProfile(userSession.profile!.updating(with: draft))
            dismiss(animated: true, completion: nil)
        }
        if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func resetErrorDisplay() {
        nameFieldView.isRejecting = false
        errorLabel.text = nil
        errorView.isHidden = true
    }
    
    private func showAlert(with error: Error) {
        if error is InputError {
            showInputError(with: error.localizedDescription)
        } else {
            resetErrorDisplay()
            let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    private func showInputError(with message: String) {
        nameFieldView.isRejecting = true
        errorView.isHidden = false
        errorLabel.text = message
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

extension CharacterPickerViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        endEditingTap.isEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        endEditingTap.isEnabled = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(false)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let result = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        if result.isEmpty {
            return true
        }
        do {
            if result.isEmpty {
                return true
            }
            try draft.intermediateNicknameValidator.validate(result)
            return true
        } catch _  {
            return false
        }
    }
}
