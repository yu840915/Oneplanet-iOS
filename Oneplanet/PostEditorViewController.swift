//
//  PostEditorViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostEditorViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var postDraft: PostDraft!
    @IBOutlet weak var okButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var placeholderLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet var endEditingTap: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapToEndEditing(_ sender: Any) {
        view.endEditing(false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

private extension PostEditorViewController {
    func updateViewsForDraft() {
        imageView.image = postDraft.images[0].localImage
        
    }
    
    func updatePlaceholderAppearance() {
        let hasText = captionTextView.text.isEmpty == false
        placeholderLabel.isHidden = hasText
    }

}

extension PostEditorViewController: UITextViewDelegate {
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
