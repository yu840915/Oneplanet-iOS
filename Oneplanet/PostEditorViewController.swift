//
//  PostEditorViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostEditorViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    
    static func fromDefaultStoryboard() -> PostEditorViewController {
        return UIStoryboard(name: "MainUserFlow", bundle: nil).instantiateViewController(withIdentifier: "PostEditorViewController") as! PostEditorViewController
    }
    var userSession: UserSession!
    var postDraft: PostDraft!
    
    @IBOutlet weak var okButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    @IBOutlet weak var photoEditorContainer: UIView!
    
    var keyboardObserver: KeyboardAppearanceObserver?
    var submitOperation: SubmitPostOperation?
    var photoEditor: PostEditorPhotoCollectionViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeContents()
        updateViewsForDraft()
        if userSession.isAdmin {
            imageView.isHidden = true
        } else {
            photoEditorContainer.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let observer = KeyboardAppearanceObserver()
        observer.keyboardWillChange = {[weak self] change in
            self?.updateViewsForKeyboardChange(change)
        }
        keyboardObserver = observer
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardObserver = nil
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }

    @IBAction func submit(_ sender: Any) {
        guard submitOperation == nil else {return}
        let op = SubmitPostOperation(draft: postDraft, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didSubmitPostDraft()
            }
        }
        submitOperation = op
        op.start()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PostEditorPhotoCollectionViewController {
            vc.isEditable = userSession.isAdmin
            vc.photoPickerAction = {[weak self] in
                self?.showPhotoPicker()
            }
            vc.deleteItemAction = {[weak self] index in
                self?.deleteAttachment(at: index)
            }
            photoEditor = vc
        }
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? PostPhotoPickingFlowViewController {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
            vc.onPickingImage = {[weak self] image in
                self?.didPickImage(image)
            }
        }
    }
}

private extension PostEditorViewController {
    func didSubmitPostDraft() {
        let op = submitOperation!
        submitOperation = nil
        if op.success == true {
            dismiss(animated: true, completion: nil)
        } else if let error = op.error {
            let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.titles.dismiss, style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    func updateViewsForKeyboardChange(_ change: KeyboardChangeInfo) {
        let intersection = contentScrollView.convert(contentScrollView.bounds, to: nil).intersection(change.endRect)
        contentScrollView.contentInset.bottom = intersection.height
    }
    
    func localizeContents() {
        title = Localized.titles.post
        okButtonItem.title = Localized.titles.share
        placeholderLabel.text = Localized.placeholder.caption
    }
    
    func updateViewsForDraft() {
        imageView.image = postDraft.images.first?.localImage
        photoEditor.attachments = postDraft.images
        captionTextView.text = postDraft.caption
        updatePlaceholderAppearance()
    }
    
    func updatePlaceholderAppearance() {
        let hasText = captionTextView.text.isEmpty == false
        placeholderLabel.isHidden = hasText
    }
    
    func showPhotoPicker() {
        performSegue(withIdentifier: SegueID.showPhotoPicker, sender: nil)
    }
    
    func deleteAttachment(at index: Int) {
        postDraft.images.remove(at: index)
        updateViewsForDraft()
    }
    
    func didPickImage(_ image: UIImage) {
        dismiss(animated: true, completion: nil)
        appendAttachment(with: image)
    }
    
    func appendAttachment(with image: UIImage) {
        postDraft.images.append(ImageAttachment(image: image))
        updateViewsForDraft()
    }
}

extension PostEditorViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let result = (textView.text as NSString).replacingCharacters(in: range, with: text)
        do {
            try postDraft.captionValidator.validate(result)
            return true
        } catch _ {
            return false
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderAppearance()
        guard textView.markedTextRange == nil else { return }
        postDraft.caption = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        endEditingTap.isEnabled = false
    }

}

extension PostEditorViewController {
    struct SegueID {
        static let showPhotoPicker = "showPhotoPicker"
    }
}
