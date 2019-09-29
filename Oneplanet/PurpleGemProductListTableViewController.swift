//
//  PurpleGemProductListTableViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit

class PurpleGemProductListTableViewController: UITableViewController, UserSessionDepending {

    var userSession: UserSession!
    private var plans: [IAPProductPlan] = []
    private var purchaseOperation: BuyPurpleGemOperation?
    
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
            self?.buyPurpleGemWithPlan(at: indexPath)
        }
        cell.updateViews(with: plan)
        return cell
    }
    
    private func buyPurpleGemWithPlan(at indexPath: IndexPath) {
        let check = FeatureAccessCheckOperation(userSession: userSession)
        check.start()
        guard check.isAccessible && purchaseOperation == nil else {return}
        let op = BuyPurpleGemOperation(plan: plans[indexPath.row], transactionProcesser: IAPTransactionProcessor.shared, session: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didBuyPurpleGem()
            }
        }
        purchaseOperation = op
        op.start()
    }
    
    private func didBuyPurpleGem() {
        let op = purchaseOperation!
        purchaseOperation = nil
        if let error = op.error {
            if error is InsufficienFundError {
                showPopUpForInsufficientFundError()
            } else {
                showAlert(with: error)
            }
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.ok, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showPopUpForInsufficientFundError() {
        dismiss(animated: true) {
            router.handle(DeepLinks.insufficientFundPopUp)
        }
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
