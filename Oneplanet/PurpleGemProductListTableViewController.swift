//
//  PurpleGemProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PurpleGemProductListTableViewController: UITableViewController {

    private var plans: [IAPProductPlan] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        if let plans = IAPTransactionProcessor.shared.prefetchedProducts.rubyProducts {
            self.plans = plans
        } else {
            IAPTransactionProcessor.shared.prefetchedProducts.initializeIfNeeded()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plans.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PurpleGemProductCell
        let plan = plans[indexPath.row]
        cell.buyAction = {[weak self] in
            
        }
        cell.updateViews(with: plan)
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

extension PurpleGemProductCell {
    func updateViews(with plan: IAPProductPlan) {
        let formatter = SharedNumberFormatters.integer
        if plan.bonus > 0 {
            nameLabel.text = String(format: Localized.phraseFormats.buySomeGetSomeFree, formatter.string(for: plan.amount)!, formatter.string(for: plan.bonus)!)
        } else {
            nameLabel.text = String(format: Localized.phraseFormats.buySome, formatter.string(for: plan.amount)!)
        }
        var priceTag = ""
        if let redeem = plan.redeem, redeem.amount > 0 {
            priceTag += formatter.string(for: plan.amount)! + " + "
        }
        priceTag +=  IAPTransactionProcessor.shared.prefetchedProducts.priceFormatter!.string(for: plan.skProduct.price)!
        buyButton.setTitle(priceTag, for: .normal)
    }
}
