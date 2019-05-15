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
    @IBOutlet weak var nicknameRuleLabel: UILabel!
    @IBOutlet weak var nameFieldView: InputFieldView!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var addAvatarButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var addAvatarView: UIStackView!
    @IBOutlet weak var avatarAddedLabel: UILabel!
    @IBOutlet weak var changeAvatarButton: UIButton!
    @IBOutlet weak var addAvatarPromptLabel: UILabel!
    @IBOutlet weak var changeAvatarView: UIStackView!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var pickImageOperation: PickImageOperation?
    var profileDraft: ProfileDraft = ProfileDraft()
    private var updateHandle: Any?
    private var downloadImageOperaion: DownloadImageOperaion?
    private var createProfileOperation: UpdateProfileOperation? {
        didSet {
            updateViewForRunningOperation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        avatarButton.layer.cornerRadius = 40.0
        avatarButton.layer.borderColor = UIColor.white.cgColor
        updateHandle = profileDraft.updateObservers.add {[weak self] in
            self?.updateViewsForDraft()
        }
        localizeTitles()
        setUpViewsForDraft()
    }
    
    deinit {
        downloadImageOperaion?.cancel()
    }
    
    private func setUpViewsForDraft() {
        if let nickname = userSession.socialProfile?.nickname {
            profileDraft.nickname = String(nickname.prefix(30))
            nameFieldView.textField.text = profileDraft.nickname
        }
        if let url = userSession.socialProfile?.avatarURL {
            let op = DownloadImageOperaion(url: url)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.didDownloadAvatar()
                }
            }
            downloadImageOperaion = op
            op.start()
        }
        updateViewsForDraft()
    }
    
    private func didDownloadAvatar() {
        let op = downloadImageOperaion!
        downloadImageOperaion = nil
        if let image = op.image, profileDraft.avatar == nil {
            profileDraft.avatar = ImageAttachment(image: image)
        }
    }
    
    private func localizeTitles() {
        nameFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.nickname, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        greetingLabel.text = Localized.phrases.newUserGreeting
        addAvatarButton.setTitle(Localized.phrases.addAvatar, for: .normal)
        addAvatarPromptLabel.text = Localized.messages.addAvatarPrompt
        changeAvatarButton.setTitle(Localized.phrases.changeAvatar, for: .normal)
        avatarAddedLabel.text = Localized.phrases.avatarAdded
        nicknameRuleLabel.text = Localized.phrases.nicknameRule
        nextButton.setTitle(Localized.titles.next, for: .normal)
    }
    
    private func updateViewsForDraft() {
        nextButton.isEnabled = !profileDraft.nickname.isEmpty
        let hasAvatar = profileDraft.avatar != nil
        if let avatar = profileDraft.avatar {
            avatarButton.setBackgroundImage(avatar.localImage, for: .normal)
            avatarButton.setImage(nil, for: .normal)
        } else {
            avatarButton.setBackgroundImage(nil, for: .normal)
            avatarButton.setImage(#imageLiteral(resourceName: "ic_addmypic_nor"), for: .normal)
        }
        if hasAvatar {
            addAvatarView.isHidden = true
            changeAvatarView.isHidden = false
            avatarButton.layer.borderWidth = 1.0
        } else {
            addAvatarView.isHidden = false
            changeAvatarView.isHidden = true
            avatarButton.layer.borderWidth = 0.0
        }
    }
    
    private func updateViewForRunningOperation() {
        let allowsAction = createProfileOperation == nil
        [addAvatarButton, changeAvatarButton, nextButton, avatarButton].forEach{$0?.isEnabled = allowsAction}
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
    
    private func resetErrorDisplay() {
        nameFieldView.isRejecting = false
        errorLabel.text = nil
        errorView.isHidden = true
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
            profileDraft.avatar = ImageAttachment(image: image) 
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
        submitProfile()
    }
    
    private func submitProfile() {
        guard createProfileOperation == nil else {
            return
        }
        let op = UpdateProfileOperation(draft: profileDraft, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSubmitProfile()
            }
        }
        createProfileOperation = op
        op.start()
    }
    
    private func didSubmitProfile() {
        let op = createProfileOperation!
        createProfileOperation = nil
        resetErrorDisplay()
        if op.success == true {
            didCreateProfile?()
        }
        if let error = op.error {
            showAlert(with: error)
        }
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
