//
//  GreenGemPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/4.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class GreenGemPopUpViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usageLabel: UILabel!
    @IBOutlet weak var bulletTextView1: UITextView!
    @IBOutlet weak var bulletTextView2: UITextView!
    @IBOutlet weak var bulletTextView3: UITextView!
    @IBOutlet weak var bulletTextView4: UITextView!
    @IBOutlet weak var bulletTextView5: UITextView!

    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func invokeGoAction(_ sender: UIButton) {
    }
    
}
