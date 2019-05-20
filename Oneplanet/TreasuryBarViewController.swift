//
//  TreasuryBarViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/17.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class TreasuryBarViewController: UIViewController {

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
        scorebarBackImage.layer.shadowColor = #colorLiteral(red: 0.3725490196, green: 0.8235294118, blue: 0.8078431373, alpha: 1)
        scorebarBackImage.layer.shadowRadius = 4
        scorebarBackImage.layer.shadowOffset = .zero
        scorebarBackImage.layer.shadowOpacity = 1.0
        scoreMaskView.layer.cornerRadius = 5.0
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
