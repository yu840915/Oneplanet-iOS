//
//  ProductListCells.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import Kingfisher
import ModelBlocks

class ProductOverviewCell: UITableViewCell {
    @IBOutlet weak var contentBackgroundView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var lockLabel: UILabel!
    @IBOutlet weak var tutorialBubble: ChatBubbleView!
    private var fadeInFadeOutOperation: FadeInFadeOutOperation?
    
    var isLocked = true {
        didSet {
            if oldValue != isLocked {
                updateViewsForLockState()
            }
        }
    }
    var unlockAction: (()->())?
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateViewsForLockState()
        tutorialBubble.titleLabel.text = Localized.tutorial.unlock
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
    }
    
    private func updateViewsForLockState() {
        let appearance = isLocked ? LockAppearance.forLocked : LockAppearance.forUnlocked
        lockLabel.text = appearance.title
        lockLabel.textColor = appearance.color
        lockButton.isEnabled = isLocked
    }
    
    @IBAction func invokeUnlockAction(_ sender: UIButton) {
        unlockAction?()
    }
    
    func showTutorial() {
        fadeInFadeOutOperation?.cancel()
        clipsToBounds = false
        superview?.bringSubviewToFront(self)
        let op = FadeInFadeOutOperation(view: tutorialBubble)
        op.completionBlock = {[weak self] in
            self?.restoreFromTutorial()
        }
        fadeInFadeOutOperation = op
        op.start()
    }
    
    override func prepareForReuse() {
        if let op = fadeInFadeOutOperation {
            op.cancel()
            fadeInFadeOutOperation = nil
            restoreFromTutorial()
        }
    }
    
    private func restoreFromTutorial() {
        clipsToBounds = true
    }
}

extension ProductOverviewCell {
    func updateViews(with overview: ProductOverview) {
        titleLabel.text = overview.displayName
        previewImageView.kf.setImage(with: overview.cover?.url)
    }
}

class LockAppearance {
    let title: String
    let color: UIColor
    init(title: String, color: UIColor) {
        self.title = title
        self.color = color
    }
    static let forLocked = LockAppearance(title: Localized.titles.unlock, color: ColorPalette.bidRed)
    static let forUnlocked = LockAppearance(title: Localized.titles.unlocked, color: ColorPalette.bidGreen)
}

class BiddingProductCell: UITableViewCell {
    @IBOutlet weak var contentBackgroundView: UIView!
    
    @IBOutlet weak var avatarContainer: UIView!
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var runningIndicator: UIActivityIndicatorView!
    @IBOutlet weak var bidButton: UIButton!
    @IBOutlet weak var hundredLabel: UILabel!
    @IBOutlet weak var tensLabel: UILabel!
    @IBOutlet weak var digitLabel: UILabel!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet var leadIndicators: [UIButton]!
    @IBOutlet weak var outcomeView: UIView!
    @IBOutlet weak var winLabel: UILabel!
    @IBOutlet weak var loseLabel: UILabel!
    private var color: UIColor = ColorPalette.bidRed
    @IBOutlet weak var tutorialBubble: ChatBubbleView!

    var bidAction: (()->())?
    var showDetailAction: (()->())?
    var showProfileAction: (()->())?
    
    private let countdownTimeAttribute: [NSAttributedString.Key: Any] = [.kern: 3.5]
    var deadline: Date? {
        didSet {
            tick()
        }
    }
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        return TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
    }()
    
    let formatter: NumberFormatter = SharedNumberFormatters.clockComponent
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentBackgroundView.backgroundColor = .white
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectedBackgroundView = CommonViewFactory.shared.makeSelectionBackground()
        previewButton.imageView?.contentMode = .scaleAspectFill
        avatarView.action = {[weak self] in
            self?.showProfileAction?()
        }
    }
    
    func tick() {
        guard let deadline = self.deadline else { return }
        let i = max(deadline.timeIntervalSinceNow, 0)
        let comps = TimeIntervalComponents(extractor.extract(from: i))
        let min = formatter.string(for: comps.minutes) ?? "00"
        let sec = formatter.string(for: comps.seconds) ?? "00"
        var attr = countdownTimeAttribute
        if i < .minute {
            attr[.foregroundColor] = color
        }
        countdownLabel.attributedText = NSAttributedString(string: min + ":" + sec, attributes: attr)
    }
    
    @IBAction func invokeDetailAction(_ sender: Any) {
        showDetailAction?()
    }
    
    @IBAction func invokeBidAction(_ sender: UIButton) {
        bidAction?()
    }
}

extension BiddingProductCell {
    func updateViews(with product: ProductOverview) {
        previewButton.kf.setImage(with: product.cover?.url, for: .normal)
    }
    
    func updateViews(with process: BidProcess) {
        if process.isInitialized {
            updateViewsWithValidProcess(process)
        } else {
            updateViewsForInitialState()
        }
    }
    
    func updateViewsForInitialState() {
        bidButton.isHidden = true
        runningIndicator.isHidden = true
        countdownLabel.isHidden = true
        outcomeView.isHidden = true
        avatarView.isHidden = true
    }
    
    func updateViewsWithValidProcess(_ process: BidProcess) {
        runningIndicator.isHidden = true
        countdownLabel.isHidden = true
        outcomeView.isHidden = true
        bidButton.isHidden = true
        avatarView.isHidden = true
        coverView.isHidden = !process.isEnded
        if process.isEnded {
            outcomeView.isHidden = false
            winLabel.isHidden = !process.isWinning
            loseLabel.isHidden = process.isWinning
        } else if let date = process.endDate {
            if date.timeIntervalSinceNow.magnitude > 1 {
                deadline = process.endDate
                countdownLabel.isHidden = false
                bidButton.isHidden = false
                bidButton.isEnabled = !process.isWinning
            } else {
                runningIndicator.isHidden = false
                runningIndicator.startAnimating()
            }
        }
        color = process.isWinning ? ColorPalette.bidGreen : ColorPalette.bidRed
        if process.leadFetcher != nil {
            avatarView.isHidden = false
            avatarView.avatar = process.lead?.avatar
        }
    }
}

class CountDownClockView: UIView {
    @IBOutlet weak var dayValueLabel: UILabel!
    @IBOutlet weak var hourValueLabel: UILabel!
    @IBOutlet weak var minuteValueLabel: UILabel!
    @IBOutlet weak var secondValueLabel: UILabel!
    
    var deadline = Date() {
        didSet {
            tick()
        }
    }
    private let attributes: [NSAttributedString.Key: Any] = [.kern: 4.67]
    let extractor: TimeIntervalComponentExtractor = {
        let sec = TimeIntervalComponentExtractor(unitInterval: .second, next: nil)
        let min = TimeIntervalComponentExtractor(unitInterval: .minute, next: sec)
        let hour = TimeIntervalComponentExtractor(unitInterval: .hour, next: min)
        return TimeIntervalComponentExtractor(unitInterval: .day, next: hour)
    }()
    let formatter: NumberFormatter = SharedNumberFormatters.clockComponent
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func tick() {
        let comps = TimeIntervalComponents(extractor.extract(from: deadline.timeIntervalSinceNow))
        dayValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.days) ?? "00", attributes: attributes)
        hourValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.hours) ?? "00", attributes: attributes)
        minuteValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.minutes) ?? "00", attributes: attributes)
        secondValueLabel.attributedText = NSAttributedString(string: formatter.string(for: comps.seconds) ?? "00", attributes: attributes)
    }
}

class BiddingStateIndicationCell: UITableViewCell {
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionTextView.linkTextAttributes = [
            .foregroundColor : ColorPalette.buttonGreen,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)]
    }
    
    fileprivate func prepareWinnerNotice() -> NSAttributedString {
        let text = String(format: Localized.messageFormats.winnerNotice, Localized.phrases.shippingInfo)
        let linkRange = (text as NSString).range(of: Localized.phrases.shippingInfo)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: text, attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.addAttributes([.link : DeepLinks.shippingInfo], range: linkRange)
        return attrStr
    }
}

class RunningBiddingIndicationCell: BiddingStateIndicationCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        stateLabel.text = Localized.activity.bidding
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrStr = NSMutableAttributedString(string: Localized.messages.ongoingBidding + "\n", attributes: [.foregroundColor : ColorPalette.defaultText, .paragraphStyle: paragraphStyle])
        attrStr.append(prepareWinnerNotice())
        descriptionTextView.attributedText = attrStr
    }
}

class BiddingEndIndicationCell: BiddingStateIndicationCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        stateLabel.text = Localized.activity.biddingEnded
        descriptionTextView.attributedText = prepareWinnerNotice()
    }
}

class ChatBubbleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }
}

class FadeInFadeOutOperation: SimpleAsynchronousOperation {
    let view: UIView
    private weak var fadeOutTimer: Timer?
    init(view: UIView) {
        self.view = view
    }
    
    override func main() {
        guard !isCancelled else { return }
        view.isHidden = false
        view.alpha = 0.0
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1.0
        }) { (_) in
            self.didFadeIn()
        }
    }
    
    private func didFadeIn() {
        guard !isCancelled else {
            view.isHidden = true
            return
        }
        scheduleFadeOut()
    }
    
    private func scheduleFadeOut() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {[weak self] (_) in
            self?.fadeOut()
        }
    }
    
    private func fadeOut() {
        guard !isCancelled else { return }
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.0
        }) { (_) in
            self.view.isHidden = true
            self.finish()
        }
    }
    
    override func onCancel() {
        fadeOutTimer?.invalidate()
        view.isHidden = true
    }
}
