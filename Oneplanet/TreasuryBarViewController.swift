//
//  TreasuryBarViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class TreasuryBarViewController: UIViewController {

    @IBOutlet weak var blueGemIcon: UIImageView!
    @IBOutlet weak var purpleGemIcon: UIImageView!
    @IBOutlet weak var greenGemIcon: UIImageView!
    
    @IBOutlet weak var scorebarButton: UIButton!
    @IBOutlet var treasuryButtons: [UIButton]!
    @IBOutlet weak var scorebarBackImage: UIImageView!
    @IBOutlet weak var scoreMaskView: UIView!
    
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
    
    private func animateLevelUp(for view: UIView, delay: TimeInterval = 0.0) {
        view.alpha = 1.0
        UIView.animate(withDuration: 1.0, delay: delay, options: [.curveLinear], animations: {
            view.transform = CGAffineTransform(scaleX: 30, y: 30).translatedBy(x: 0, y: 1)
            view.alpha = 0
        }) { (_) in
            view.transform = .identity
            view.alpha = 0.0
        }
    }
    @IBAction func animatePurpleGen(_ sender: UIButton) {
        animateLevelUp(for: purpleGemIcon, delay: 0.0)
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
