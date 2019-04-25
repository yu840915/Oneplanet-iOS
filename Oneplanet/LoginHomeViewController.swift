//
//  LoginHomeViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

protocol AuthorizationFlowEntryPoint: AnyObject {
    var authorizationCompletion: ((UserSession)->())! {set get}
}

class LoginHomeViewController: UIViewController, AuthorizationFlowEntryPoint {
    var authorizationCompletion: ((UserSession) -> ())!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginPromptLabel: UILabel!
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var guestLoginButton: UIButton!
    @IBOutlet weak var termsTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationBarStyle.translucent.configure(navigationController!.navigationBar)
        navigationController!.navigationBar.barStyle = .blackTranslucent
        navigationItem.hidesBackButton = true
        localizeTitles()
        prepareTermsTextView()
    }
    
    private func localizeTitles() {
        signUpButton.setTitle(Localized.titles.signUp, for: .normal)
        logInButton.setTitle(Localized.titles.logIn, for: .normal)
        loginPromptLabel.text = Localized.messages.loginPrompt
        guestLoginButton.setTitle(Localized.phrase.geustLogin, for: .normal)
    }
    
    private func prepareTermsTextView() {
        
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
