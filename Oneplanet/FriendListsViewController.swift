//
//  FriendListsViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class FriendListsViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {
    
    var userSession: UserSession!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController,
            nav.viewControllers.count == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localized.titles.done, style: .done, target: self, action: #selector(exit(_:)))
        }
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let controllers = [FollowerListTableViewController.fromDefaultStoryboard(), FollowingListTableViewController.fromDefaultStoryboard()]
        controllers
            .compactMap{$0 as? UserSessionDepending}
            .forEach{$0.userSession = userSession}
        return controllers
    }

    @IBAction func exit(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
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
