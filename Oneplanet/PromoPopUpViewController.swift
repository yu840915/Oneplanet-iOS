//
//  PromoPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PromoPopUpViewController: UIViewController {

    @IBOutlet weak var goButton: UIButton!
    var page: PromotionPage!
    var dismissAction: (()->())?
    var linkHandler: ((URL)->(Bool))?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func goToLink(_ sender: UIButton) {
        guard let link = page.link else {return}
        if linkHandler?(link) == true {
        } else {
            performSegue(withIdentifier: "showWebView", sender: link)
        }
    }
    
    @IBAction func exit(_ sender: UIButton) {
        dismissAction?()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? WebViewController {
            vc.request = URLRequest(url: sender as! URL)
        }
    }
}
