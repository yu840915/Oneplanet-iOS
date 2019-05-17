//
//  AvatarView.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher

class AvatarView: UIView {
    @IBOutlet var avatarButton: UIButton!
    var action: (()->())? {
        didSet {
            updateButtonInteraction()
        }
    }
    var borderColor: UIColor? {
        didSet {
            updateBoarderColor()
        }
    }
    var avatar: WebImageInfo? {
        didSet {
            if oldValue != avatar {
                updateAvatar()
            }
        }
    }
    private var fetchOperation: DownloadImageOperaion?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2
        updateBoarderColor()
        updateButtonInteraction()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        avatarButton.layer.cornerRadius = avatarButton.bounds.width / 2
    }
    
    private func updateBoarderColor() {
        layer.borderColor = borderColor?.cgColor
    }
    
    private func updateButtonInteraction() {
        avatarButton.isUserInteractionEnabled = (action != nil)
    }
    
    private func updateAvatar() {
        setDefaultAvatar()
        guard let info = avatar else {
            cancelDownload()
            return
        }
        if info.accessToken != nil {
            if let op = fetchOperation, op.info == info {
                return
            }
            cancelDownload()
            let op = DownloadImageOperaion(info: info)
            op.completionBlock = {[weak self] in
                OperationQueue.main.addOperation {
                    self?.didDownloadImage()
                }
            }
            op.start()
            fetchOperation = op
        } else {
            cancelDownload()
            avatarButton.kf.setBackgroundImage(with: info.url, for: .normal)
        }
    }
    
    private func setDefaultAvatar() {
        avatarButton.setBackgroundImage(#imageLiteral(resourceName: "im_userphotodefault_nor"), for: .normal)
    }
    
    private func didDownloadImage() {
        let op = fetchOperation!
        fetchOperation = nil
        if let image = op.image {
           avatarButton.setBackgroundImage(image, for: .normal)
        }
    }
    
    private func cancelDownload() {
        fetchOperation?.cancel()
        fetchOperation = nil
    }
    
    @IBAction func invokeAction(_ sender: UIButton) {
        action?()
    }
}
