//
//  BuyRubyOperation.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/11/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class BuyRubyFlowOperation: SimpleAsynchronousOperation, FailableOperationType {
    var success: Bool?
    var error: Error?
    let plan: IAPProductPlan
    let userSession: UserSession
    let form: TPDForm
    let cardholderInfo: CardholderInfoDraft
    private var cardTokenizer: TPDCard?
    private var buyRubyOperation: BuyRubyOperation?
    
    init(form: TPDForm, plan: IAPProductPlan, cardholderInfo: CardholderInfoDraft, userSession: UserSession) {
        self.plan = plan
        self.userSession = userSession
        self.form = form
        self.cardholderInfo = cardholderInfo
    }
    
    override func main() {
        do {
            try cardholderInfo.validate()
            getPrime()
        } catch let error {
            fail(with: error)
        }
    }
    
    private func getPrime() {
        let tokenizer = TPDCard.setup(form)
        cardTokenizer = tokenizer
        tokenizer.onSuccessCallback {[weak self] (prime, card, cardID) in
            self?.handleSuccess(prime: prime, cardInfo: card, cardID: cardID)
        }.onFailureCallback {[weak self] (status, message) in
            self?.fail(with: GenericAppError(message, code: status))
        }.getPrime()
    }
    
    private func handleSuccess(prime: String?, cardInfo: TPDCardInfo?, cardID: String?) {
        if let prime = prime {
            buyRuby(with: prime)
        } else {
            fail(with: GenericAppError("Unkown payment gateway error"))
        }
    }
    
    private func buyRuby(with prime: String) {
        let op = BuyRubyOperation(prime: prime, plan: plan, cardholderInfo: cardholderInfo, userSession: userSession)
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
        success = op.success
        error = op.error
        if success == true {
            userSession.wallet.setNeedsUpdate()
        }
        finish()
    }
    
    private func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}

class BuyRubyOperation: AlamofireAPIAccessOperation {
    let cardholderInfo: CardholderInfoDraft
    let userSession: UserSession
    let plan: IAPProductPlan
    let prime: String
    
    init(prime: String, plan: IAPProductPlan, cardholderInfo: CardholderInfoDraft, userSession: UserSession) {
        self.plan = plan
        self.userSession = userSession
        self.prime = prime
        self.cardholderInfo = cardholderInfo
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        try cardholderInfo.validate()
        let params: Parameters = ["product_id": plan.productID, "prime": prime, "name": cardholderInfo.name, "email": cardholderInfo.email, "phone_number": cardholderInfo.country!.cellPhoneContryCode +  cardholderInfo.phoneNumber]
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("wallet/purchase/tappay"), method: .post, parameters: params, encoding: JSONEncoding.default, headers: userSession.authorizationHeader)
    }
    
    override func processErrorData(with data: Data, response: HTTPURLResponse) throws {
        if let msg = try? JSONDecoder.default.decode(ErrorMessage.self, from: data) {
            throw GenericAppError(msg.message, code: response.statusCode)
        } else {
            try super.processErrorData(with: data, response: response)
        }
    }
}

class ErrorMessage: Decodable {
    let message: String
}
