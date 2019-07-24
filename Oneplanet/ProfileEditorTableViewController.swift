//
//  ProfileEditorTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/21.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProfileEditorTableViewController: UITableViewController, UserSessionDepending {
    
    var userSession: UserSession! {
        didSet {
            profileDraft = ProfileDraft(profile: profile)
        }
    }
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
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var pickerToolBar: UIToolbar!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    @IBOutlet weak var genderTitleItem: UIBarButtonItem!
    @IBOutlet weak var doneItem: UIBarButtonItem!
    
    fileprivate var profileDraft: ProfileDraft!
    fileprivate var pickImageOperation: PickImageOperation?
    fileprivate var getAvatarOperation: DownloadImageOperaion?
    
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    private var draftDidChangeHandle: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avatarView.action = {[weak self] in
            self?.showPickerSelectionSheet()
        }
        draftDidChangeHandle = profileDraft.updateObservers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.updateViewsForDraft()
            }
        }
        
        UIPickerView.appearance(whenContainedInInstancesOf: [UIView.self]).backgroundColor = .clear
        genderTitleItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 17)], for: .normal)
        genderTitleItem.isEnabled = false
        [cancelItem, doneItem].forEach{
            $0.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 17, weight: .semibold)], for: .normal)
        }
        genderField.inputView = pickerView
        genderField.inputAccessoryView = pickerToolBar
        localizeTitles()
        getAvatar()
        updateViewsForSession()
        updateViewsForDraft()
    }
    
    deinit {
        pickImageOperation?.cancel()
        submitChangesIfNeeded()
    }

    private func localizeTitles() {
        title = Localized.phrases.editProfile
        changeAvatarButton.setTitle(Localized.phrases.changeAvatar, for: .normal)
        copyIdButton.setTitle(Localized.phrases.copyID, for: .normal)
        nicknameLabel.text = Localized.titles.nickname
        userIdLabel.text = Localized.titles.userId
        privateInfoLabel.text = Localized.titles.privateInformation
        genderLabel.text = Localized.titles.gender
        emailLabel.text = Localized.titles.email
        cancelItem.title = Localized.titles.cancel
        genderTitleItem.title = Localized.titles.gender
        doneItem.title = Localized.titles.done
    }
    
    @IBAction func updateNickname(_ sender: UITextField) {
        guard sender.markedTextRange == nil else { return }
        profileDraft.nickname = sender.text ?? ""
    }
    
    @IBAction func copyId(_ sender: UIButton) {
        UIPasteboard.general.string = profile.displayID
        Toast.show(with: String(format: Localized.messageFormats.didCopyMyId, profile.displayID))
    }
    
    @IBAction func startImagePickingFlow(_ sender: UIButton) {
        showPickerSelectionSheet()
    }

    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }
    
    @IBAction func cancelGenderPicking(_ sender: UIBarButtonItem) {
        view.endEditing(false)
        updateViewsForDraft()
    }
    
    @IBAction func commitPickedGender(_ sender: UIBarButtonItem) {
        view.endEditing(false)
        let row = pickerView.selectedRow(inComponent: 0)
        profileDraft.gender = Gender.options[row]
    }
}

fileprivate extension ProfileEditorTableViewController {
    func submitChangesIfNeeded() {
        guard profileDraft.isDirty else { return }
        userSession.submitProfileChanges(with: profileDraft)
    }
    
    func getAvatar() {
        guard let avatar = profile.avatar else {return}
        let op = DownloadImageOperaion(info: avatar)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetAvatar()
            }
        }
        getAvatarOperation = op
        op.start()
    }
    
    func didGetAvatar() {
        let op = getAvatarOperation!
        getAvatarOperation = nil
        if let image = op.image,
            let avatar = profile.avatar,
            profileDraft.avatar == nil {
            profileDraft.setDefaultAvatarIfAllowed(ImageAttachment(image: image, info: avatar)) 
        }
    }
    
    func updateViewsForSession() {
        userIdField.text = profile.displayID
        emailField.text = userSession.loginType.displayName
    }
    
    func updateViewsForDraft() {
        avatarView.attachment = profileDraft.avatar
        avatarView.backgrondImage = profile.character?.race.frameImage
        nicknameField.text = profileDraft.nickname
        genderField.text = profileDraft.gender.displayName
    }

    func showPickerSelectionSheet() {
        let sheet = UIAlertController(title: Localized.phrases.changeAvatar, message: nil, preferredStyle: .actionSheet)
        if profileDraft.avatar != nil {
            sheet.addAction(UIAlertAction(title: Localized.titles.delete, style: .destructive, handler: {[weak self] (_) in
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
        if textField === genderField {
            if let row = Gender.options.index(of: profileDraft.gender) {
                pickerView.selectRow(row, inComponent: 0, animated: false)
            }
        }
        return true
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
        guard textField == nicknameField else { return false }
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

extension ProfileEditorTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Gender.options.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: Gender.options[row].displayName, attributes: [.foregroundColor : ColorPalette.defaultText])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        genderField.text = Gender.options[row].displayName
    }
}
