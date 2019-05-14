//
//  ProfileDetailViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/14.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProfileDetailViewController: UIViewController, UserSessionDepending, DefaultInstanceFactory {
    var userSession: UserSession!
    class func fromDefaultStoryboard() -> ProfileDetailViewController {
        return UIStoryboard(name: "Me", bundle: nil).instantiateViewController(withIdentifier: "ProfileDetailViewController") as! ProfileDetailViewController
    }
    
    @IBOutlet weak var chooseRaceButton: UIButton!
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var raceImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: UIView.noIntrinsicMetric, height: 475)
        localizeTitles()
    }
    
    private func localizeTitles() {
        actionButton.setTitle(Localized.phrases.follow, for: .normal)
        actionButton.setTitle(Localized.phrases.following, for: .selected)
        actionButton.setTitle(Localized.phrases.following, for: [.selected, .highlighted])
        chooseRaceButton.setTitle(Localized.phrases.chooseAlien, for: .normal)
    }
    
    @IBAction func startChooseRece(_ sender: UIButton) {
    }
    
    @IBAction func performAction(_ sender: UIButton) {
    }
}

class AvatarView: UIView {
    @IBOutlet var imageView: UIImageView!
    var borderColor: UIColor? {
        didSet {
            updateBoarderColor()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2
        updateBoarderColor()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        imageView.layer.cornerRadius = imageView.bounds.width / 2
    }
    
    private func updateBoarderColor() {
        layer.borderColor = borderColor?.cgColor
    }
}
