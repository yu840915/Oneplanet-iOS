//
//  PurchaseActions.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/29.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import StoreKit
import ModelBlocks
import Alamofire

class BuyPurpleGemOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    
    let transactionProcesser: IAPTransactionProcessor
    let session: UserSession
    let plan: IAPProductPlan
    private var buyIAPProductOperation: BuyIAPProductOperation?
    private var buyRubyOperation: PurchaseOperation?
    
    init(plan: IAPProductPlan, transactionProcesser: IAPTransactionProcessor, session: UserSession) {
        self.transactionProcesser = transactionProcesser
        self.session = session
        self.plan = plan
    }
    
    override func main() {
        guard plan.currency == .purpleGem else {
            fail(with: GenericAppError("Unsupported purchase type"))
            return
        }
        if let redeem = plan.redeem,
            let cur = redeem.currency,
            plan.amount > session.wallet.balance(for: cur).total {
            fail(with: InsufficienFundError(currency: cur))
            return
        }
        guard let inv = Invoice(iapProduct: plan.skProduct, associatedProductID: nil) else {
            fail(with: GenericAppError("Cannot create invoice"))
            return
        }
        let op = BuyIAPProductOperation(invoice: inv, transactionProcesser: transactionProcesser)
        op.completionBlock = {[weak self] in
            self?.didPurchaseIAPProduct()
        }
        buyIAPProductOperation = op
        op.start()
    }
    
    private func didPurchaseIAPProduct() {
        let op = buyIAPProductOperation!
        guard let transaction = op.invoice.transaction  else {
            fail(with: GenericAppError("Missing SKTransaction "))
            return
        }
        if op.success == true {
            purchaseRuby(with: transaction)
        } else {
            fail(with: op.error)
        }
    }
    
    private func purchaseRuby(with transaction: SKPaymentTransaction) {
        guard let data = transactionProcesser.readReceipt() else {
            fail(with: GenericAppError("Cannot read receipt"))
            return
        }
        let op = PurchaseOperation(transaction: transaction, receiptData: data, session: session)
        op.completionBlock = {[weak self] in
            self?.didBuyRuby()
        }
        buyRubyOperation = op
        op.start()
    }
    
    private func didBuyRuby() {
        let op = buyRubyOperation!
        if op.success == true {
            transactionProcesser.finishTransaction(op.transaction)
            session.wallet.setNeedsUpdate()
            success = true
            finish()
        } else {
            fail(with: op.error)
        }
    }
    
    func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}

class UnlockWithBlueGemOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    
    let transactionProcesser: IAPTransactionProcessor
    let session: UserSession
    let product: ProductOverview
    private var invoice: Invoice?
    private var buyIAPProductOperation: BuyIAPProductOperation?
    private var buyGreenGemOperation: PurchaseOperation?
    private var unlockOperation: UnlockProductOperation?
    private(set) var shouldShowCompensationPopUp = false
    
    init(product: ProductOverview, transactionProcesser: IAPTransactionProcessor, session: UserSession) {
        self.transactionProcesser = transactionProcesser
        self.session = session
        self.product = product
    }
    
    override func main() {
        if session.wallet.balance(for: .blueGem).total < 0 {
            fail(with: InsufficienFundError(currency: .blueGem))
            return
        }
        guard let skProduct = transactionProcesser.prefetchedProducts.unlockProduct else {
            fail(with: GenericAppError("IAP Store is not ready"))
            transactionProcesser.prefetchedProducts.initializeIfNeeded()
            return
        }
        guard let inv = Invoice(iapProduct: skProduct, associatedProductID: product.id) else {
            fail(with: GenericAppError("Cannot create invoice"))
            return
        }
        let op = BuyIAPProductOperation(invoice: inv, transactionProcesser: transactionProcesser)
        op.completionBlock = {[weak self] in
            self?.didPurchaseIAPProduct()
        }
        buyIAPProductOperation = op
        op.start()
    }
    
    private func didPurchaseIAPProduct() {
        let op = buyIAPProductOperation!
        guard let transaction = op.invoice.transaction  else {
            fail(with: GenericAppError("Missing SKTransaction "))
            return
        }
        if op.success == true {
            purchaseGreenGem(with: transaction)
        } else {
            fail(with: op.error)
        }
    }
    
    private func purchaseGreenGem(with transaction: SKPaymentTransaction) {
        guard let data = transactionProcesser.readReceipt() else {
            fail(with: GenericAppError("Cannot read receipt"))
            return
        }
        let op = PurchaseOperation(transaction: transaction, receiptData: data, session: session)
        op.completionBlock = {[weak self] in
            self?.didBuyGreenGem()
        }
        buyGreenGemOperation = op
        op.start()
    }
    
    private func didBuyGreenGem() {
        let op = buyGreenGemOperation!
        if op.success == true {
            unlockProduct()
            transactionProcesser.finishTransaction(op.transaction)
        } else {
            fail(with: op.error)
        }
    }

    private func unlockProduct() {
        let op = UnlockProductOperation(product: product, session: session, currency: .greenGem)
        op.completionBlock = {[weak self] in
            self?.didUnlockProduct()
        }
        unlockOperation = op
        op.start()
    }
    
    private func didUnlockProduct() {
        let op = unlockOperation!
        if op.success == true {
            success = true
        } else {
            success = false
            shouldShowCompensationPopUp = true
            error = op.error
        }
        finish()
        session.wallet.setNeedsUpdate()
    }

    func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}

class BuyIAPProductOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    
    let transactionProcesser: IAPTransactionProcessor
    let invoice: Invoice
    private var invoiceHandle: Any!

    init(invoice: Invoice, transactionProcesser: IAPTransactionProcessor) {
        self.transactionProcesser = transactionProcesser
        self.invoice = invoice
    }
    
    override func main() {
        guard transactionProcesser.canPlaceOrder else {
                fail(with: GenericAppError("Cannot create invoice"))
                return
        }
        invoiceHandle = invoice.updateObservers.add {[weak self] in
            self?.invoiceDidUpdate()
        }
        transactionProcesser.placeOrder(with: invoice)
    }
    
    private func invoiceDidUpdate() {
        guard let transaction = invoice.transaction else {
            return
        }
        switch transaction.transactionState {
        case .failed:
            fail(with: transaction.error)
        case .purchased, .restored:
            success = true
            finish()
        case .deferred, .purchasing: break
        }
    }
    
    func fail(with error: Error?) {
        self.error = error
        success = false
        finish()
    }
}

class PurchaseOperation: AlamofireAPIAccessOperation {
    let transaction: SKPaymentTransaction
    let receiptData: Data
    let session: UserSession
    
    init(transaction: SKPaymentTransaction, receiptData: Data, session: UserSession) {
        self.transaction = transaction
        self.receiptData = receiptData
        self.session = session
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        guard let id = transaction.transactionIdentifier else {
            throw GenericAppError("Missing transaction ID")
        }
        let params: Parameters = ["transaction_id": id, "receipt": receiptData.base64EncodedString()]
        return Alamofire.request(ServiceURLs.base.appendingPathComponent("wallet/purchase/IAP"), method: .post, parameters: params, encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
}
