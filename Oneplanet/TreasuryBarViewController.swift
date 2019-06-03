//
//  TreasuryBarViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import ModelBlocks

class TreasuryBarViewController: UIViewController {
    
    var maxVisibleScorebarWidth: CGFloat {
        return scoreMaskView.bounds.width
    }
    @IBOutlet weak var visibleScorebarWidth: NSLayoutConstraint!
    @IBOutlet weak var blueGemIcon: UIImageView!
    @IBOutlet weak var purpleGemIcon: UIImageView!
    @IBOutlet weak var greenGemIcon: UIImageView!
    
    @IBOutlet weak var scorebarButton: UIButton!
    @IBOutlet var treasuryButtons: [UIButton]!
    @IBOutlet weak var scorebarBackImage: UIImageView!
    @IBOutlet weak var scoreMaskView: UIView!
    private var levelUpAnimation: LevelUpAnimationOperation?
    
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
        let op = LevelUpAnimationOperation(view: view)
        levelUpAnimation = op
        op.start()
    }
    @IBAction func animatePurpleGen(_ sender: UIButton) {
        animateLevelUp(for: blueGemIcon)
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

class LevelUpAnimationOperation: SimpleAsynchronousOperation {
    let view: UIView
    init(view: UIView) {
        self.view = view
    }
    
    override func main() {
        view.alpha = 1.0
        UIView.animate(withDuration: 1.0, animations: {
            self.view.transform = CGAffineTransform(scaleX: 30, y: 30).translatedBy(x: 0, y: 1)
            self.view.alpha = 0
        }) { (_) in
            self.view.transform = .identity
            self.view.alpha = 0.0
        }
    }
}
