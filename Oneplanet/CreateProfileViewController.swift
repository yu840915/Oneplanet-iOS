//
//  CreateProfileViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/27.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class CreateProfileViewController: UIViewController, UserSessionDepending {
    
    var didCreateProfile: (()->())?
    var userSession: UserSession!
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
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    
    private var pickImageOperation: PickImageOperation?
    var profileDraft: ProfileDraft = ProfileDraft()
    private var updateHandle: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        avatarImageView.layer.cornerRadius = 40.0
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        updateHandle = profileDraft.updateObservers.add {[weak self] in
            self?.updateViewsForDraft()
        }
        localizeTitles()
        updateViewsForDraft()
    }
    
    private func localizeTitles() {
        nameFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.nickname, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        greetingLabel.text = Localized.phrases.newUserGreeting
        addAvatarButton.setTitle(Localized.phrases.addAvatar, for: .normal)
        addAvatarPromptLabel.text = Localized.messages.addAvatarPrompt
        changeAvatarButton.setTitle(Localized.phrases.changeAvatar, for: .normal)
        avatarAddedLabel.text = Localized.phrases.avatarAdded
        nextButton.setTitle(Localized.titles.next, for: .normal)
    }
    
    private func updateViewsForDraft() {
        nextButton.isEnabled = profileDraft.isValid
        let hasAvatar = profileDraft.avatar != nil
        if let avatar = profileDraft.avatar {
            avatarImageView.image = avatar
        } else {
            avatarImageView.image = #imageLiteral(resourceName: "ic_addmypic_nor")
        }
        if hasAvatar {
            addAvatarView.isHidden = true
            changeAvatarView.isHidden = false
            avatarImageView.layer.borderWidth = 1.0
        } else {
            addAvatarView.isHidden = false
            changeAvatarView.isHidden = true
            avatarImageView.layer.borderWidth = 0.0
        }
    }

    private func showPickerSelectionSheet() {
        let sheet = UIAlertController(title: Localized.phrases.changeAvatar, message: nil, preferredStyle: .actionSheet)
        if profileDraft.avatar != nil {
            sheet.addAction(UIAlertAction(title: Localized.phrases.removeAvatar, style: .destructive, handler: {[weak self] (_) in
                self?.deleteAvatar()
            }))
        }
        sheet.addAction(UIAlertAction(title: Localized.phrases.takePhoto, style: .default, handler: {[weak self] (_) in
            self?.showCameraPicker()
        }))
        sheet.addAction(UIAlertAction(title: Localized.phrases.fromLibrary, style: .default, handler: { [weak self] (_) in
            self?.showLibraryPicker()
        }))
        sheet.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    private func deleteAvatar() {
        profileDraft.avatar = nil
        updateViewsForDraft()
    }
    
    private func showCameraPicker() {
        showPicker(with: PickCameraImageOperation(initialCameraPosition: .front, presenter: self))
    }
    
    private func showLibraryPicker() {
        showPicker(with: PickLibraryImageOperation(presenter: self))
    }
    
    private func showPicker(with operation: PickImageOperation) {
        operation.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didPickImage()
            }
        }
        pickImageOperation = operation
        operation.start()
    }
    
    private func didPickImage() {
        let op = pickImageOperation!
        pickImageOperation = nil
        if let image = op.image {
            profileDraft.avatar = image
            updateViewsForDraft()
        } else if let error = op.error {
            handlePickImageFailure(with: error)
        }
    }
    
    private func handlePickImageFailure(with error: Error) {
        let alert = UIAlertController(title: Localized.errorTitles.cannotPickAvatar, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        if error is MissingInputPermissionError {
            alert.addAction(UIAlertAction(title: Localized.phrases.openSettings, style: .default, handler: {(_) in
                UIApplication.shared.open(ServiceURLs.appSettings, options: [:], completionHandler: nil)
            }))
        }
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func submitProfile(_ sender: UIButton) {
        view.endEditing(false)
        profileDraft.nickname = nameFieldView.textField.text ?? ""
    }
    
    @IBAction func endEditing(_ sender: UITapGestureRecognizer) {
        view.endEditing(false)
    }
    
    @IBAction func updateNickname(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        profileDraft.nickname = sender.text ?? ""
    }
    
    @IBAction func startImagePickingFlow(_ sender: UIButton) {
        showPickerSelectionSheet()
    }
}

extension CreateProfileViewController: UITextFieldDelegate {
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
            try profileDraft.intermediateNicknameValidator.validate(result)
            return true
        } catch _  {
            return false
        }
    }
}

class ProfileDraft {
    let updateObservers = MulticastCallbackNode<()->()>()
    let intermediateNicknameValidator = InputLengthValidator(max: 30)
    let nicknameValidator = AndValidator([NonEmptyInputValidator(), InputLengthValidator(max: 30)])
    var nickname: String = "" {
        didSet {
            if oldValue != nickname {
                updateObservers.invokeEach{$0()}
            }
        }
    }
    var avatar: UIImage?

    func validate() throws {
        try nicknameValidator.validate(nickname)
    }
    
    var isValid: Bool {
        do {
            try validate()
            return true
        } catch _ {
            return false
        }
    }
}
