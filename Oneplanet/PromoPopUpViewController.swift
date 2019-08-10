//
//  PromoPopUpViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher

class PromoPopUpViewController: UIViewController {

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var page: PromotionAd!
    var dismissAction: (()->())?
    var linkHandler: ((URL)->(Bool))?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        goButton.setTitle(Localized.titles.go, for: .normal)
        updateViewsForPage()
    }
    
    private func updateViewsForPage() {
        goButton.isHidden = (page.link == nil)
        imageView.kf.setImage(with: page.poster.url)
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
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
            vc.exitTitle = Localized.titles.done
            vc.request = URLRequest(url: sender as! URL)
        }
    }
}
