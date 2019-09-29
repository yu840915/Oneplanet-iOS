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

    let prefetchedProducts = PrefetchedIAPProducts()
    
    private override init() {}
    
    weak var userSession: UserSession?
    private(set) var waitingInvoice: Invoice?
    private(set) var pendingTransactions: [SKPaymentTransaction] = []
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach{ handleUpdate(of: $0, in: queue) }
    }
    
    private func handleUpdate(of transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        switch transaction.transactionState {
        case .deferred:
            if waitingInvoice?.setTransactionIfAllowed(transaction) == true {
                waitingInvoice?.notifyStateChange()
            }
        case .failed:
            if waitingInvoice?.isRelated(to: transaction) == true {
                waitingInvoice?.notifyStateChange()
                waitingInvoice = nil
            }
            queue.finishTransaction(transaction)
        case .purchasing:
            if waitingInvoice?.setTransactionIfAllowed(transaction) == true {
                waitingInvoice?.notifyStateChange()
            }
        case .purchased:
            if waitingInvoice?.isRelated(to: transaction) == true {
                waitingInvoice = nil
                waitingInvoice?.notifyStateChange()
            } else {
                pendingTransactions.append(transaction)
            }
        case .restored:
            break
        }
    }
    
    func finishTransaction(in invoice: Invoice) {
        guard let transaction = invoice.transaction else {
            return
        }
        finishTransaction(transaction)
    }
    
    func finishTransaction(_ transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    var canPlaceOrder: Bool {
        guard let session = userSession,
            !session.isAdmin && !session.isGuest else {
            return false
        }
        if waitingInvoice != nil {
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
    
    func readReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        do {
            return try Data(contentsOf: url)
        } catch let error {
            logger.error("Cannot read receipt \(error)")
            return nil
        }
    }
}

class Invoice {
    let iapProduct: SKProduct
    let iapType: IAPProductType
    let associatedProductID: String?
    private(set) var transaction: SKPaymentTransaction?
    let updateObservers = MulticastCallbackNode<()->()>()
    
    init?(iapProduct: SKProduct, associatedProductID: String?) {
        guard let type = IAPProductType.from(iapProduct.productIdentifier) else {
            return nil
        }
        self.associatedProductID = associatedProductID
        iapType = type
        self.iapProduct = iapProduct
    }
    
    @discardableResult func setTransactionIfAllowed(_ transaction: SKPaymentTransaction) -> Bool {
        if self.transaction === transaction {
            return true
        }
        guard self.transaction == nil && isRelated(to: transaction) else {
            return false
        }
        self.transaction = transaction
        return true
    }
    
    func isRelated(to transaction: SKPaymentTransaction) -> Bool {
        guard transaction.payment.productIdentifier == iapProduct.productIdentifier else {
            return false
        }
        return true
    }
    
    func notifyStateChange() {
        if transaction != nil {
            updateObservers.invokeEach{$0()}
        }
    }
}

class PrefetchedIAPProducts {
    private(set) var priceFormatter: NumberFormatter?
    private(set) var unlockProduct: SKProduct?
    private(set) var bidProduct: SKProduct?
    private(set) var rubyProducts: [IAPProductPlan]?
    private var getProductOperation: GetSKProductsOperation?
    private var getRubyProdcutsOperation: PrepareRubyProductListOperation?
    private var retryExpCounter = 0
    
    init() {
        getProduct()
        getRubyList()
    }
    
    func initializeIfNeeded() {
        if rubyProducts == nil {
            getRubyList()
        }
        if unlockProduct == nil || bidProduct == nil {
            getProduct()
        }
    }
    
    private func getRubyList() {
        guard getRubyProdcutsOperation == nil else {
            return
        }
        let op = PrepareRubyProductListOperation()
        op.completionBlock = {[weak self] in
            self?.didGetRubyList()
        }
        getRubyProdcutsOperation = op
        op.start()
    }
    
    private func didGetRubyList() {
        let op = getRubyProdcutsOperation!
        getRubyProdcutsOperation = nil
        if op.success == true {
            rubyProducts = op.plans
        }
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

class PrepareRubyProductListOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var plans: [IAPProductPlan] = []
    private var rubyPlans: [IAPProductPlan] = []
    private var rubyPlanDict: [String: IAPProductPlan] = [:]
    
    private var getPlanOperation: GetIAPProductPlanOperation?
    private var getSKProductsOperations: GetSKProductsOperation?
    
    override func main() {
        let op = GetIAPProductPlanOperation()
        op.completionBlock = {[weak self] in
            self?.didGetPlan()
        }
        getPlanOperation = op
        op.start()
    }
    
    private func didGetPlan() {
        let op = getPlanOperation!
        if op.success == true {
            getRubyProducts(from: op.plans)
        } else {
            fail(with: op.error)
        }
    }
    
    private func getRubyProducts(from plans: [IAPProductPlan]) {
        let rubyPlans = plans.filter{IAPProductType.from($0.productID) == .ruby}
        guard !rubyPlans.isEmpty else {
            success = true
            finish()
            return
        }
        self.rubyPlans = rubyPlans
        rubyPlans.forEach{rubyPlanDict[$0.productID] = $0}
        let op = GetSKProductsOperation(productIDs: rubyPlans.map{$0.productID})
        op.completionBlock = {[weak self] in
            self?.handelDidGetSKProducts()
        }
        getSKProductsOperations = op
        op.start()
    }
    
    private func handelDidGetSKProducts() {
        let op = getSKProductsOperations!
        if op.success == true {
            op.products.forEach{rubyPlanDict[$0.productIdentifier]?.associate(with: $0)}
            plans = rubyPlans.filter{$0.skProduct != nil}
            success = true
            finish()
        } else {
            fail(with: op.error)
        }
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
    }
}

class GetIAPProductPlanOperation: AlamofireAPIAccessOperation {
    private(set) var plans: [IAPProductPlan] = []
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: ServiceURLs.base.appendingPathComponent("wallet/purchase/plans"))
    }
    
    override func processData(with data: Data) throws {
        plans = try JSONDecoder.default.decode([IAPProductPlan].self, from: data)
    }
}

class IAPProductPlan: Decodable {
    private(set) var skProduct: SKProduct!
    let productID: String
    let currencyID: String
    var currency: BalanceAccount? {
        return BalanceAccount(rawValue: currencyID)
    }
    let amount: Int
    let bonus: Int
    let redeem: IAPProductRedeemPlan?

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case currencyID = "currency"
        case amount, bonus, redeem
    }
    
    func associate(with product: SKProduct) {
        if product.productIdentifier == productID {
            self.skProduct = product
        }
    }
}

class IAPProductRedeemPlan: Decodable {
    let currencyID: String
    var currency: BalanceAccount? {
        return BalanceAccount(rawValue: currencyID)
    }
    let amount: Int
    
    enum CodingKeys: String, CodingKey {
        case currencyID = "diamond"
        case amount
    }
}

class InsufficienFundError: GenericAppError {
    let currency: BalanceAccount
    
    init(currency: BalanceAccount) {
        self.currency = currency
        super.init("Insufficient balance of \(currency.displayName)")
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
