//
//  FullscreenLoadingViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class FullscreenLoadingViewController: UIViewController, DefaultInstanceFactory {
    
    class func fromDefaultStoryboard() -> FullscreenLoadingViewController {
        return UIStoryboard(name: "SupportingFlows", bundle: nil).instantiateViewController(withIdentifier: "FullscreenLoadingViewController") as! FullscreenLoadingViewController
    }

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadingIndicator.startAnimating()
    }
}
