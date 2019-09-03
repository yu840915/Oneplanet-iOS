//
//  IAPTransactionProcessor.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/6/30.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import StoreKit
import ModelBlocks

class IAPTransactionProcessor: NSObject, SKPaymentTransactionObserver {
    static let shared = IAPTransactionProcessor()

    let blueGemRelatedProducts = BlueGemRelatedIAPProducts()
    
    private override init() {}
    
    private(set) weak var userSession: UserSession?
    private(set) var waitingInvoice: Invoice?
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach{handleUpdate(of: $0, in: queue) }
    }
    
    private func handleUpdate(of transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        switch transaction.transactionState {
        case .deferred: break
        case .failed:
            if waitingInvoice?.mayBeRelated(to: transaction) == true {
                waitingInvoice = nil
            }
        case .purchasing:
            break
        case .purchased:
            break
        case .restored:
            break
        }
    }
    
    var canPlaceOrder: Bool {
        if userSession == nil && waitingInvoice == nil {
            return false
        }
        return true
    }
    
    func placeOrder(with invoice: Invoice) {
        guard canPlaceOrder else {
            fatalError("Should check before placing order")
        }
        waitingInvoice = invoice
        SKPaymentQueue.default().add(SKPayment(product: invoice.iapProduct))
    }
}

class Invoice {
    let iapProduct: SKProduct
    let iapType: IAPProductType
    let associatedProductID: String?
    var transaction: SKPaymentTransaction?
    
    init?(iapProduct: SKProduct, associatedProductID: String?) {
        guard let type = IAPProductType.from(iapProduct.productIdentifier) else {
            return nil
        }
        self.associatedProductID = associatedProductID
        iapType = type
        self.iapProduct = iapProduct
    }
    
    func mayBeRelated(to transaction: SKPaymentTransaction) -> Bool {
        guard transaction.payment.productIdentifier == iapProduct.productIdentifier else {
            return false
        }
        return true
    }
}

class BlueGemRelatedIAPProducts {
    private(set) var priceFormatter: NumberFormatter?
    private(set) var unlockProduct: SKProduct?
    private(set) var bidProduct: SKProduct?
    private var getProductOperation: GetSKProductsOperation?
    private var retryExpCounter = 0
    
    init() {
        getProduct()
    }
    
    private func getProduct() {
        guard getProductOperation == nil else {
            return
        }
        let op = GetSKProductsOperation(productIDs: [IAPProductIdentifiers.bid, IAPProductIdentifiers.unlock])
        op.completionBlock = {[weak self] in
            self?.didGetProduct()
        }
        getProductOperation = op
        op.start()
    }
    
    private func didGetProduct() {
        let op = getProductOperation!
        getProductOperation = nil
        op.products.forEach{
            if $0.productIdentifier == IAPProductIdentifiers.bid {
                bidProduct = $0
            } else if $0.productIdentifier == IAPProductIdentifiers.unlock {
                unlockProduct = $0
            }
        }
        setUpFormatterIfNeeded()
        if bidProduct == nil || unlockProduct == nil {
            Timer.scheduledTimer(withTimeInterval: TimeInterval(pow(2, Double(retryExpCounter))),
                                 repeats: false) {[weak self] (_) in
                self?.getProduct()
            }
            retryExpCounter += 1
        }
    }
    
    private func setUpFormatterIfNeeded() {
        guard priceFormatter == nil, let prod = bidProduct ?? unlockProduct else {
            return
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyISOCode
        formatter.locale = prod.priceLocale
        priceFormatter = formatter
    }
}

enum IAPProductType: Equatable {
    case unlock
    case bid
    case ruby
    
    static func from(_ productID: String) -> IAPProductType? {
        if productID == IAPProductIdentifiers.bid {
            return .bid
        } else if productID == IAPProductIdentifiers.unlock {
            return .unlock
        } else if productID.contains("ruby") {
            return .ruby
        }
        return nil
    }
}

class GetSKProductsOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var products: [SKProduct] = []
    private(set) var success: Bool?
    private(set) var error: Error?
    private var productRequest: SKProductsRequest?
    
    init(productIDs: [String]) {
        productRequest = !productIDs.isEmpty ? SKProductsRequest(productIdentifiers: Set(productIDs)) : nil
    }
    
    override func main() {
        guard !isCancelled else { return }
        if let request = productRequest {
            request.delegate = self
            request.start()
        } else {
            finish()
        }
    }
    
    override func onCancel() {
        productRequest?.cancel()
    }
}

extension GetSKProductsOperation: SKProductsRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        guard !isCancelled else { return }
        success = true
        request.delegate = nil
        finish()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        guard !isCancelled else { return }
        products = response.products
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard !isCancelled else { return }
        success = false
        self.error = error
        request.delegate = nil
        finish()
    }
}

