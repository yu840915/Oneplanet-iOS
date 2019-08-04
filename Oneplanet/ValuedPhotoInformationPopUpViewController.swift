//
//  ValuedPhotoInformationPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ValuedPhotoInformationPopUpViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var hideButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeContents()
    }
    
    func localizeContents() {
        okButton.setTitle(Localized.phrases.iGetIt, for: .normal)
        
    }
    
    @IBAction func next(_ sender: Any) {
    }
    
    @IBAction func toggleHide(_ sender: UIButton) {
    }

}
