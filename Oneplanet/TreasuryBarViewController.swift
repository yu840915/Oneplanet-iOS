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
