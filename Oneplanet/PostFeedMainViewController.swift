//
//  PostFeedMainViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/25.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PostFeedMainViewController: ButtonBarPagerTabStripViewController, UserSessionDepending {

    var userSession: UserSession!
    @IBOutlet weak var buttonBarContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonBarContainer.translatesAutoresizingMaskIntoConstraints = false
        changeCurrentIndexProgressive = {[weak self] (oldCell, newCell, progressPercentage, changeCurrentIndex, animated) in
            self?.updateButtonBarCell(oldCell: oldCell, newCell: newCell, progressPercentage: progressPercentage, changeCurrentIndex: changeCurrentIndex, animated: animated)
        }
        navigationItem.backBarButtonItem = BarButtonItemFactory.shared.makeTitlelessBack()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PagerStyleConfigurer().configure(self)
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let latest = PostFeedTableViewController.fromDefaultStoryboard()
        latest.title = Localized.phrases.latestPosts
        latest.userSession = userSession
        let promoted = PostFeedTableViewController.fromDefaultStoryboard()
        promoted.userSession = userSession
        promoted.title = Localized.phrases.bestPosts
        return [latest, promoted]
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

private extension PostFeedMainViewController {
    func updateButtonBarCell(oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) {
        guard changeCurrentIndex else { return }
        oldCell?.label.textColor = PagerStyleConfigurer.Style.normal.titleColor
        oldCell?.label.font = PagerStyleConfigurer.Style.normal.font
        newCell?.label.textColor = PagerStyleConfigurer.Style.highlighted.titleColor
        newCell?.label.font = PagerStyleConfigurer.Style.highlighted.font
    }
}
