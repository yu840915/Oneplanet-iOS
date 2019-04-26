//
//  SignUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var socialLoginLabel: UILabel!
    @IBOutlet weak var emailLoginLabel: UILabel!
    @IBOutlet weak var emailFieldView: InputFieldView!
    @IBOutlet weak var inputErrorView: UIView!
    @IBOutlet weak var inputErrorLabel: UILabel!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    private func localizeTitles() {
        title = Localized.titles.signUp
        socialLoginLabel.text = Localized.phrase.socialLogin
        emailLoginLabel.text = Localized.phrase.emailSignUp
        emailFieldView.textField.attributedPlaceholder = NSAttributedString(string: Localized.placeholder.email, attributes: [NSAttributedString.Key.foregroundColor : ColorPalette.defaultPlaceholder])
        signUpButton.setTitle(Localized.titles.signUp, for: .normal)
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

class InputFieldView: UIView {
    @IBOutlet weak var normalBackgroundImage: UIImageView!
    @IBOutlet weak var rejectingBackgroundImage: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    var isRejecting = false {
        didSet {
            updateWithRejectingState()
        }
    }
    
    override func awakeFromNib() {
        updateWithRejectingState()
    }
    
    private func updateWithRejectingState() {
        if isRejecting {
            normalBackgroundImage.isHidden = true
            rejectingBackgroundImage.isHidden = false
        } else {
            normalBackgroundImage.isHidden = false
            rejectingBackgroundImage.isHidden = true

        }
    }
}
