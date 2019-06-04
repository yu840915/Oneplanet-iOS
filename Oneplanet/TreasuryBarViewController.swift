//
//  TreasuryBarViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class TreasuryBarViewController: UIViewController, UserSessionDepending {
    
    var userSession: UserSession!
    var maxVisibleScorebarWidth: CGFloat {
        return scoreMaskView.bounds.width
    }
    @IBOutlet weak var visibleScorebarWidth: NSLayoutConstraint!
    @IBOutlet weak var blueGemIcon: UIImageView!
    @IBOutlet weak var purpleGemIcon: UIImageView!
    @IBOutlet weak var greenGemIcon: UIImageView!
    
    @IBOutlet weak var scorebarContainer: UIView!
    @IBOutlet weak var scorebarButton: UIButton!
    @IBOutlet var treasuryButtons: [UIButton]!
    @IBOutlet weak var scorebarBackImage: UIImageView!
    @IBOutlet weak var scoreMaskView: UIView!
    private var levelUpAnimation: LevelUpAnimationOperation?
    private var blueGemLevelUpAnimation: Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let colors = [ColorPalette.blueGem, ColorPalette.purpleCoin, ColorPalette.greenKey]
        for i in 0...2 {
            let button = treasuryButtons[i]
            button.imageView?.layer.shadowColor = colors[i].cgColor
            button.imageView?.layer.shadowRadius = 10
            button.imageView?.layer.shadowOffset = .zero
            button.imageView?.layer.shadowOpacity = 1.0
            button.imageView?.clipsToBounds = false
        }
        scorebarButton.layer.shadowColor = #colorLiteral(red: 0.3725490196, green: 0.8235294118, blue: 0.8078431373, alpha: 1)
        scorebarButton.layer.shadowRadius = 4
        scorebarButton.layer.shadowOffset = .zero
        scorebarButton.layer.shadowOpacity = 1.0
        scoreMaskView.layer.cornerRadius = 5.0
    }
    
    private func animateLevelUp(for view: UIView) {
        let op = LevelUpAnimationOperation(icon: view)
        levelUpAnimation = op
        op.start()
    }
    

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        let op = FeatureAccessCheckOperation(userSession: userSession)
        op.start()
        return op.isAccessible
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

fileprivate extension TreasuryBarViewController {
    func showLevelUpAnimation(forSegueID segueID: String) {
        switch segueID {
        case "showBlueGemPopUP":
            let op = BlueGemLevelUpAnimation(icon: blueGemIcon, endProgress: 0.3, containerView: scorebarContainer, scorebarLengthConstraint: visibleScorebarWidth)
            blueGemLevelUpAnimation = op

            op.start()
        case "showPurpleGemPopUP":
            levelUpAnimation = LevelUpAnimationOperation(icon: purpleGemIcon)
            levelUpAnimation?.start()
        case "showGreenGemPopUP":
            levelUpAnimation = LevelUpAnimationOperation(icon: greenGemIcon)
            levelUpAnimation?.start()
        default: break
        }
    }
    
    
}

class LevelUpAnimationOperation: SimpleAsynchronousOperation {
    let icon: UIView
    init(icon: UIView) {
        self.icon = icon
    }
    
    override func main() {
        icon.alpha = 1.0
        UIView.animate(withDuration: 1.0, animations: {
            self.icon.transform = CGAffineTransform(scaleX: 30, y: 30).translatedBy(x: 0, y: 1)
            self.icon.alpha = 0
        }) { (_) in
            self.icon.transform = .identity
            self.icon.alpha = 0.0
            self.finish()
        }
    }
}

class ScoreBarAnimation: SimpleAsynchronousOperation {
    let endProgress: CGFloat
    let containerView: UIView
    let scorebarLengthConstraint: NSLayoutConstraint
    private let fullDuration: TimeInterval = 4

    init(endProgress: CGFloat, containerView: UIView, scorebarLengthConstraint: NSLayoutConstraint) {
        self.endProgress = endProgress
        self.containerView = containerView
        self.scorebarLengthConstraint = scorebarLengthConstraint
    }
    
    override func main() {
        guard !isCancelled else { return }
        let ratio: TimeInterval = TimeInterval(endProgress - scorebarLengthConstraint.constant / containerView.frame.width)
        scorebarLengthConstraint.constant = endProgress * containerView.frame.width
        UIView.animate(withDuration: ratio * fullDuration, delay: 0, options: [.curveLinear], animations: {
            self.containerView.layoutIfNeeded()
        }) {[weak self] (_) in
            self?.finish()
        }
    }
}

class BlueGemLevelUpAnimation: SimpleAsynchronousOperation {
    let icon: UIView
    let endProgress: CGFloat
    let containerView: UIView
    let scorebarLengthConstraint: NSLayoutConstraint
    private var levelUpAnimation: LevelUpAnimationOperation?
    private let fullDuration: TimeInterval = 4
    
    init(icon: UIView, endProgress: CGFloat, containerView: UIView, scorebarLengthConstraint: NSLayoutConstraint) {
        self.icon = icon
        self.endProgress = endProgress
        self.containerView = containerView
        self.scorebarLengthConstraint = scorebarLengthConstraint
    }
    
    override func main() {
        animateBarFull()
    }
    
    private func animateBarFull() {
        guard !isCancelled else { return }
        let ratio: TimeInterval = 1 - TimeInterval(scorebarLengthConstraint.constant / containerView.frame.width)
        scorebarLengthConstraint.constant = containerView.frame.width
        UIView.animate(withDuration: ratio * fullDuration, delay: 0, options: [.curveLinear], animations: {
            self.containerView.layoutIfNeeded()
        }) {[weak self] (_) in
            OperationQueue.main.addOperation {
                self?.animateLevelUp()
            }
        }
    }
    
    private func animateLevelUp() {
        guard !isCancelled else { return }
        let op = LevelUpAnimationOperation(icon: icon)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.animateToEndProgress()
            }
        }
        levelUpAnimation = op
        op.start()
    }
    
    private func animateToEndProgress() {
        guard !isCancelled else { return }
        scorebarLengthConstraint.constant = 0
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
        scorebarLengthConstraint.constant = endProgress * containerView.frame.width
        UIView.animate(withDuration: TimeInterval(endProgress) * fullDuration, delay: 0, options: [.curveLinear], animations: {
            self.containerView.layoutIfNeeded()
        }) {[weak self] (_) in
            self?.finish()
        }
    }
}
