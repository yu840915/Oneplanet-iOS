//
//  ProfileEditorTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/21.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProfileEditorTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var profile: MyProfile! { return userSession.profile }
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var changeAvatarButton: UIButton!
    @IBOutlet weak var copyIdButton: UIButton!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    @IBOutlet weak var privateInfoLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var genderLabel: UILabel!
    
    @IBOutlet weak var nicknameField: UITextField!
    @IBOutlet weak var userIdField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var genderField: UITextField!
    fileprivate var profileDraft: ProfileDraft!
    fileprivate var pickImageOperation: PickImageOperation?
    
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarView.action = {[weak self] in
            self?.showPickerSelectionSheet()
        }
        localizeTitles()
    }
    
    private func localizeTitles() {
        changeAvatarButton.setTitle(Localized.phrases.changeAvatar, for: .normal)
        copyIdButton.setTitle(Localized.phrases.copyID, for: .normal)
        nicknameLabel.text = Localized.titles.nickname
        userIdLabel.text = Localized.titles.userId
        privateInfoLabel.text = Localized.titles.privateInformation
        genderLabel.text = Localized.titles.gender
        emailLabel.text = Localized.titles.email
    }
    
    @IBAction func copyId(_ sender: UIButton) {
        UIPasteboard.general.string = profile.id
    }
    
    @IBAction func startImagePickingFlow(_ sender: UIButton) {
        showPickerSelectionSheet()
    }

    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }
}

fileprivate extension ProfileEditorTableViewController {
    func updateViewsForDraft() {
        avatarView.avatar = userSession.profile?.avatar
        
    }

    func showPickerSelectionSheet() {
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
    
    func deleteAvatar() {
        profileDraft.avatar = nil
        updateViewsForDraft()
    }
    
    func showCameraPicker() {
        showPicker(with: PickCameraImageOperation(initialCameraPosition: .front, presenter: self))
    }
    
    func showLibraryPicker() {
        showPicker(with: PickLibraryImageOperation(presenter: self))
    }
    
    func showPicker(with operation: PickImageOperation) {
        operation.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didPickImage()
            }
        }
        pickImageOperation = operation
        operation.start()
    }
    
    func didPickImage() {
        let op = pickImageOperation!
        pickImageOperation = nil
        if let image = op.image {
            profileDraft.avatar = ImageAttachment(image: image)
            updateViewsForDraft()
        } else if let error = op.error {
            handlePickImageFailure(with: error)
        }
    }
    
    func handlePickImageFailure(with error: Error) {
        let alert = UIAlertController(title: Localized.errorTitles.cannotPickAvatar, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
        if error is MissingInputPermissionError {
            alert.addAction(UIAlertAction(title: Localized.phrases.openSettings, style: .default, handler: {(_) in
                UIApplication.shared.open(ServiceURLs.appSettings, options: [:], completionHandler: nil)
            }))
        }
        present(alert, animated: true, completion: nil)
    }

}

extension ProfileEditorTableViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return textField == nicknameField
    }
    
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
