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
    
    @IBOutlet weak var blueGemButton: UIButton!
    @IBOutlet weak var purpleGemButton: UIButton!
    @IBOutlet weak var greenGemButton: UIButton!
    
    @IBOutlet weak var scoreMaskView: UIView!
    private var greenGemLevelUpAnimation: LevelUpAnimationOperation?
    private var purpleGemLevelUpAnimation: LevelUpAnimationOperation?
    private var blueGemLevelUpAnimation: BlueGemLevelUpAnimation?
    private var scoreAnimation: ScoreBarAnimation?
    fileprivate var userActionRounter: URLRouter!
    fileprivate var animationPlan: AnimationPlan?
    private(set) var scoreProgress: CGFloat = 0
    private var snapshot: BalanceSnapshot?
    private var updateHandle: Any?
    private var allowAnimation = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        prepareRouter()
        prepareForWallet()
    }
    
    private func prepareForWallet() {
        updateHandle = userSession.wallet.updateObservers.add {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleWalletUpdate()
            }
        }
        handleWalletUpdate()
    }
    
    private func handleWalletUpdate() {
        let wallet = userSession.wallet!
        let new = BalanceSnapshot(blueGem: wallet.blueGem.total, purpleGem: wallet.purpleGem.total, greenGem: wallet.greenGem.total, score: wallet.score.total)
        scoreProgress = min(CGFloat(new.score) / 100, 1)
        debugPrint("Score \(new.score)")

        if let old = snapshot, allowAnimation {
            var plan = AnimationPlan()
            plan.blueGem = new.blueGem > old.blueGem
            plan.greenGem = new.greenGem > old.greenGem
            plan.purpleGem = new.purpleGem > old.purpleGem
            plan.scoreBar = (new.score != new.score) || plan.blueGem
            animationPlan = plan
        } else {
            visibleScorebarWidth.constant = scoreProgress * scorebarContainer.frame.width
            scorebarContainer.setNeedsLayout()
        }
        snapshot = new
        updateViewsForBalance()
        animateUpdateIfNeeded()
        if wallet.isFullyInitialized {
            allowAnimation = true
        }
    }
    
    private func updateViewsForBalance() {
        guard let source = snapshot else {
            return
        }
        let formatter = SharedNumberFormatters.wallet
        blueGemButton.setTitle(formatter.string(for: source.blueGem), for: .normal)
        purpleGemButton.setTitle(formatter.string(for: source.purpleGem), for: .normal)
        greenGemButton.setTitle(formatter.string(for: source.greenGem), for: .normal)
    }
    
    private func setUpViews() {
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

    deinit {
        router.removeOverridingRouter(userActionRounter)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
}

fileprivate extension TreasuryBarViewController {
    func prepareRouter() {
        let actionRouter = URLRouter()
        actionRouter.add(DeepLinks.blueGemPopUp.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.showBlueGemPopUp()
            }
            return true
        }
        actionRouter.add(DeepLinks.purpleGemPopUp.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.showPurpleGemPopUp()
            }
            return true
        }
        actionRouter.add(DeepLinks.greenGemPopUp.path) {[weak self] (info) -> Bool in
            OperationQueue.main.addOperation {
                self?.showGreenGemPopUp()
            }
            return true
        }
        
        userActionRounter = actionRouter
        router.addOverridingRouter(actionRouter)
    }
    
    func showBlueGemPopUp() {
        showPopUpController(BlueGemPopUpViewController.entryPoint())
    }
    
    func showGreenGemPopUp() {
        showPopUpController(GreenGemPopUpViewController.entryPoint())
    }
    
    func showPurpleGemPopUp() {
        showPopUpController(PurpleGemStoreViewController.entryPoint())
    }

    func showPopUpController(_ controller: PopUpContainerViewController) {
        let presenter = FrontViewControllerFinder.findFront() ?? self
        presenter.present(controller, animated: true, completion: nil)
    }
}

fileprivate extension TreasuryBarViewController {
    struct AnimationPlan {
        var blueGem = false
        var scoreBar = false
        var purpleGem = false
        var greenGem = false
        
        var shouldAnimate: Bool {
            return scoreBar || blueGem || purpleGem || greenGem
        }
    }
    
    struct BalanceSnapshot {
        let blueGem: Int
        let purpleGem: Int
        let greenGem: Int
        let score: Int
    }
}

fileprivate extension TreasuryBarViewController {
    func animateUpdateIfNeeded() {
        guard let plan = animationPlan else { return }
        animationPlan = nil
        if plan.blueGem {
            let op = BlueGemLevelUpAnimation(icon: blueGemIcon, endProgress: scoreProgress, containerView: scorebarContainer, scorebarLengthConstraint: visibleScorebarWidth)
            op.completionBlock = {[weak self] in
                self?.blueGemLevelUpAnimation = nil
            }
            blueGemLevelUpAnimation = op
            op.start()
        } else if plan.scoreBar {
            let op = ScoreBarAnimation(endProgress: scoreProgress, containerView: scorebarContainer, scorebarLengthConstraint: visibleScorebarWidth)
            op.completionBlock = {[weak self] in
                self?.scoreAnimation = nil
            }
            scoreAnimation = op
            op.start()
        }
        if plan.greenGem {
            let op = LevelUpAnimationOperation(icon: greenGemIcon)
            op.completionBlock = {[weak self] in
                self?.greenGemLevelUpAnimation = nil
            }
            greenGemLevelUpAnimation = op
            op.start()

        }
        if plan.purpleGem {
            let op =  LevelUpAnimationOperation(icon: purpleGemIcon)
            op.completionBlock = {[weak self] in
                self?.purpleGemLevelUpAnimation = nil
            }
            purpleGemLevelUpAnimation = op
            op.start()
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
