//
//  PurpleGemProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PurpleGemProductListTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PurpleGemProductCell

        return cell
    }

}

class PurpleGemProductCell: UITableViewCell {
    var buyAction: (()->())?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    @IBAction func invokeBuyAction(_ sender: UIButton) {
        self.buyAction?()
    }
}

