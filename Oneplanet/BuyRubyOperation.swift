//
//  BuyRubyOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/11/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks


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
