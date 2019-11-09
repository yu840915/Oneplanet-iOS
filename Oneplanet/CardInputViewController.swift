//
//  CardInputViewController.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/11/9.
//  Copyright © 2019 何一品居. All rights reserved.
//

import UIKit
import TPDirect
import ModelBlocks

class CardInputViewController: UIViewController, UserSessionDepending {

    var userSession: UserSession!
    var plan: IAPProductPlan!
    var successHandler: (()->())?
    @IBOutlet weak var cardView: UIView!
    var cardForm : TPDForm!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    private var buyRubyOperation: BuyRubyOperation? {
        didSet {
            updateBuyButton()
        }
    }
    private var lastStatus: TPDStatus?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cancelItem.title = Localized.titles.cancel
        buyButton.isEnabled = false
        cardForm = TPDForm.setup(withContainer: cardView)
        cardForm.setErrorColor(ColorPalette.alertRed)
        cardForm.setOkColor(.black)
        cardForm.setNormalColor(.gray)
        cardForm.setIsUsedCcv(true)
        cardForm.onFormUpdated {[weak self] (status) in
            OperationQueue.main.addOperation {
                self?.updateViewsForFormStatus(status)
            }
        }
    }
    
    private func updateViewsForFormStatus(_ status: TPDStatus) {
        lastStatus = status
        updateBuyButton()
    }
    
    private func updateBuyButton() {
        buyButton.isEnabled = buyRubyOperation == nil && lastStatus?.isCanGetPrime() == true
    }
    
    @IBAction func exit(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buy(_ sender: UIButton) {
        guard buyRubyOperation == nil else {
            return
        }
        let op = BuyRubyOperation(form: cardForm, plan: plan, userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didBuyRuby()
            }
        }
        buyRubyOperation = op
        op.start()
    }
    
    private func didBuyRuby() {
        let op = buyRubyOperation!
        buyRubyOperation = nil
        if op.success == true {
            successHandler?()
        } else if let error = op.error {
            showAlert(with: error)
        }
    }
    
    private func showAlert(with error: Error) {
        let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localized.titles.cancel, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


class BuyRubyOperation: SimpleAsynchronousOperation, FailableOperationType {
    var success: Bool?
    var error: Error?
    let plan: IAPProductPlan
    let userSession: UserSession
    let form: TPDForm
    private var cardTokenizer: TPDCard?
    
    init(form: TPDForm, plan: IAPProductPlan, userSession: UserSession) {
        self.plan = plan
        self.userSession = userSession
        self.form = form
    }
    
    override func main() {
        guard let fraudId = TPDSetup.shareInstance().getFraudID() else {
            fail(with: GenericAppError("Unknown error"))
            return
        }
        let tokenizer = TPDCard.setup(form)
        cardTokenizer = tokenizer
        tokenizer.onSuccessCallback {[weak self] (prime, card, cardID) in
            self?.handleSuccess(prime: prime, cardInfo: card, cardID: cardID)
        }.onFailureCallback {[weak self] (status, message) in
            self?.fail(with: GenericAppError(message, code: status))
        }.getPrime()
    }
    
    private func handleSuccess(prime: String?, cardInfo: TPDCardInfo?, cardID: String?) {
        success = true
        finish()
    }
    
    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}
