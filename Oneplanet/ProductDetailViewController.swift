//
//  ProductDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/19.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProductDetailViewController: UIViewController, UserSessionDepending {

    var userSession: UserSession!
    @IBOutlet weak var lockView: UIStackView!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localizeTitles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController,
            nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }

}

private extension ProductDetailViewController {
    func localizeTitles() {
        title = Localized.phrases.bidLot
        updateViewsForLockState()
    }
    
    func updateViewsForLockState() {
        let isLocked = true
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        lockLabel.text = appearance.title
        lockLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }

}
