//
//  PostCardCell.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/26.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PostCardCell: UITableViewCell {
    var mainAction: (()->())?
    var moreActions: (()->())?
    var showProfileAction: (()->())?
    
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var moreActionButton: UIButton!
    @IBOutlet weak var galleryCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contentLabel: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
        avatarView.action = {[weak self] in
            self?.showProfileAction?()
        }
    }
    
    @IBAction func invokeAction(_ sender: UIButton) {
        mainAction?()
    }
    
    @IBAction func invokeMoreAction(_ sender: UIButton) {
        moreActions?()
    }
    
}

class ReportedPostCell: UITableViewCell {
    var showPostAction: (()->())?
    
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var showPostButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainLabel.text = Localized.phrases.thanksForReportingPost
        detailLabel.text = Localized.messages.thanksForReportingPost
        showPostButton.setTitle(Localized.phrases.showPost, for: .normal)
    }
    
    @IBAction func invokeShowPostAction(_ sender: UIButton) {
        showPostAction?()
    }
    
}
