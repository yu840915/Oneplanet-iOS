//
//  ProductListHeader.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/13.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class ProductListHeader: UITableViewHeaderFooterView {
    class func defaultNib() -> UINib {
        return UINib(nibName: "ProductListHeader", bundle: nil)
    }
    class func height() -> CGFloat {
        return 31.0
    }
    
    var title: String = "" {
        didSet {
            if oldValue != title {
                updateForTitle()
            }
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    var showFilterAction: (()->())?
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var bubbleView: ChatBubbleView!
    
    @IBOutlet weak var unlockBubbleView: ChatBubbleView!
    
    
    private var fadeInFadeOutOperation: FadeInFadeOutOperation?
    @IBAction func showFilter(_ sender: UIButton) {
        showFilterAction?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = Localized.titles.filter
        bubbleView.titleLabel.text = Localized.tutorial.waitForBid
        unlockBubbleView.titleLabel.text = Localized.tutorial.unlock
    }
    
    private func updateForTitle() {
        let attrStr = NSMutableAttributedString(string: title + " ", attributes: [.foregroundColor : ColorPalette.defaultText])
        attrStr.append(NSAttributedString(attachment: TextAttachmentFactory.shared.arrowDown()))
        filterButton.setAttributedTitle(attrStr, for: .normal)
    }
    
    func showUnlockTutorial() {
        fadeInFadeOutOperation?.cancel()
        clipsToBounds = false
        superview?.bringSubviewToFront(self)
        let op = FadeInFadeOutOperation(view: unlockBubbleView)
        op.completionBlock = {[weak self] in
            self?.restoreFromTutorial()
        }
        fadeInFadeOutOperation = op
        op.start()
    }
    
    func showTutorial() {
        fadeInFadeOutOperation?.cancel()
        clipsToBounds = false
        superview?.bringSubviewToFront(self)
        let op = FadeInFadeOutOperation(view: bubbleView)
        op.completionBlock = {[weak self] in
            self?.restoreFromTutorial()
        }
        fadeInFadeOutOperation = op
        op.start()
    }
    
    private func restoreFromTutorial() {
        fadeInFadeOutOperation = nil
    }
    
    override func prepareForReuse() {
        if let op = fadeInFadeOutOperation {
            op.cancel()
            fadeInFadeOutOperation = nil
            restoreFromTutorial()
        }
    }
}
