//
//  PostDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostDetailViewController: UIViewController {

    @IBOutlet weak var galleryCollectionView: UICollectionView!
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var moreButtonItem: UIBarButtonItem!
    @IBOutlet weak var reportedPostView: ReportedPostView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let nav = navigationController, nav.viewControllers.count == 1 {
            NavigationBarStyle.darkGray.configure(nav.navigationBar)
        }
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showMoreActionSheet(_ sender: UIBarButtonItem) {
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

class ReportedPostView: UIStackView {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var showPostButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.text = Localized.phrases.thanksForReportingPost
        detailLabel.text = Localized.messages.thanksForReportingPost
        showPostButton.setTitle(Localized.phrases.showPost, for: .normal)
    }

}
