//
//  UserOverviewCell.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/7/22.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class UserOverviewCell: UITableViewCell {
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    var action: (()->())?
    
    @IBAction func invokeAction(_ sender: Any) {
        action?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    func updateViews(with dataSource: UserOverviewDisplayable) {
        avatarView.avatar = dataSource.avatar
        avatarView.backgrondImage = dataSource.character?.race.frameImage
        nameLabel.text = dataSource.displayName
        idLabel.text = dataSource.displayID
        actionButton.setTitle(dataSource.actionTitle, for: .normal)
        actionButton.setTitle(dataSource.selectedActionTitle, for: .selected)
        actionButton.setTitle(dataSource.selectedActionTitle, for: [.selected, .highlighted])
        actionButton.setTitleColor(ColorPalette.defaultPlaceholder, for: [.selected, .highlighted])
        actionButton.setBackgroundImage(UIImage(named: "bt_smallwiregray_nor"), for: [.selected, .highlighted])
    }
}

protocol UserOverviewDisplayable {
    var avatar: WebImageInfo? {get}
    var displayName: String {get}
    var displayID: String {get}
    var actionTitle: String {get}
    var character: Character? {get}
    var selectedActionTitle: String? {get}
}
