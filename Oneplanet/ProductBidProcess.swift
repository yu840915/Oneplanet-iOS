//
//  ProductBidProcess.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class ProductBidProcessManager {
    lazy var pushListener: PushListener = PushListener()
    private weak var userSession: UserSession!
    private var processes: [String: ProductBidProcess] = [:]
    var isEnded: Bool {
        return !processes.contains{$0.value.isEnded == false}
    }
    var winningProcesses: [ProductBidProcess] {
        return processes.map{$0.value}.filter{$0.isWinning}
    }
    private var updateClock: UpdateClock!
    
    init(userSession: UserSession) {
        self.userSession = userSession
        updateClock = UpdateClock(preferredFrameRate: 10, onTick: {[weak self] in
            self?.invokeCheck()
        })
    }
    
    private func invokeCheck() {
        processes.forEach{$0.value.checkFinalStateIfNeeded()}
        processes.forEach{$0.value.intervalRefreshNewsIfNeeded()}
    }
    
    func process(for product: ProductOverview) -> ProductBidProcess {
        if let process = processes[product.id] {
            return process
        }
        let process = ProductBidProcess(product: product, pushListener: pushListener, userSession: userSession)
        processes[product.id] = process
        return process
    }
    
    func refreshIfChannelNotConnected() {
        processes.forEach{$0.value.refreshIfChannelNotConnected()}
    }
}

class ProductBidProcess: Equatable {
    static func == (lhs: ProductBidProcess, rhs: ProductBidProcess) -> Bool {
        return lhs === rhs
    }
    
    let product: ProductOverview
    let userSession: UserSession
    let pushListener: PushListener
    var isInitialized: Bool {
        return news != nil
    }
    var extensionDuration: TimeInterval = .minute
    private var news: BidNews?
    private var getNewsOperation: GetBidNewsOperation?
    private var newsChannel: PushChannel?
    private var chennelID: Any!
    var lead: User? {
        return leadFetcher?.user
    }
    private(set) var isEnded: Bool = false {
        didSet {
            if isEnded {
                newsChannel = nil
            }
        }
    }
    var shouldBeEnded: Bool {
        if let date = endDate {
            return date.timeIntervalSinceNow < 0
        }
        return false
    }
    var isWinning: Bool {
        if leadFetcher?.id == userSession.profile?.id {
            return true
        }
        return false
    }
    private(set) var leadFetcher: UserFetcher?
    private(set) var endDate: Date?
    private(set) var myBid: Int = 0
    private(set) var getBidCountOperation: GetMyBidCountOperation?
    private(set) weak var checkFinalStateTimer: Timer?
    private var lastUpdateDate = Date()
    private var checkOutcomeOperation: CheckBidOutcomeOperation?
    
    init(product: ProductOverview, pushListener: PushListener, userSession: UserSession) {
        self.product = product
        self.pushListener = pushListener
        self.userSession = userSession
        prepareChannel()
        getNews()
        reloadBidCount()
    }
    
    deinit {
        getNewsOperation?.cancel()
        getBidCountOperation?.cancel()
        checkFinalStateTimer?.invalidate()
        checkOutcomeOperation?.cancel()
    }
    
    func refreshIfChannelNotConnected() {
        if newsChannel?.isConnected == true {
            return
        }
        getNews()
        reloadBidCount()
    }
    
    func intervalRefreshNewsIfNeeded() {
        if isEnded || newsChannel?.isConnected == true { return }
        let d = lastUpdateDate.timeIntervalSinceNow.magnitude
        let winningCase = isWinning && d > 1
        let losingCase = !isWinning && d > 5
        if winningCase || losingCase {
            logger.debug("[Bid] Start polling state of \(product.displayName) - \(product.id)")
            getNews()
        }
    }

    private func prepareChannel() {
        let channel = pushListener.subscribeChannel(ofName: product.id)
        chennelID = channel.addEventHandler(for: "bid") {[weak self] (data) in
            OperationQueue.main.addOperation {
                self?.handleBidEvent(data)
            }
        }
        newsChannel = channel
    }
    
    func checkFinalStateIfNeeded() {
        guard !isEnded && shouldBeEnded else {  return }
        guard checkFinalStateTimer == nil && checkOutcomeOperation == nil else { return }
        var delay: TimeInterval = 0.5
        if !isWinning {
            let extra = TimeInterval(Int.random(in: 0...50)) / 10
            delay = 1.0 + extra
        }
        let timer = Timer(timeInterval: delay, repeats: false) {[weak self] (_) in
            self?.checkFinalOutcome()
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        checkFinalStateTimer = timer
    }
    
    private func checkFinalOutcome() {
        guard checkOutcomeOperation == nil else { return }
        let op = CheckBidOutcomeOperation(product: product, userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didCheckOutcome()
            }
        }
        checkOutcomeOperation = op
        op.start()
    }
    
    private func didCheckOutcome() {
        let op = checkOutcomeOperation!
        checkOutcomeOperation = nil
        if let news = op.outcome {
            update(with: news)
            isEnded = op.isFinal
        }
    }
    
    private func getNews() {
        guard getNewsOperation == nil else { return }
        let op = GetBidNewsOperation(product: product, userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetNews()
            }
        }
        getNewsOperation = op
        op.start()
    }
    
    private func didGetNews() {
        let op = getNewsOperation!
        getNewsOperation = nil
        if let news = op.news {
            OperationQueue.main.addOperation {[weak self] in
                self?.update(with: news)
            }
        } else {
            lastUpdateDate = lastUpdateDate.addingTimeInterval(1)
        }
    }
    
    private func handleBidEvent(_ data: Any?) {
        if let news = BidNews(data) {
            update(with: news)
        }
    }
    
    private func update(with news: BidNews) {
        if userSession.isAdmin || userSession.profile?.id == news.userID {
            reloadBidCount()
        }
        if let currentEnd = endDate, currentEnd > news.endDate {
            return
        }
        if let currentBid = self.news?.bidTimeMs {
            if let newBid = news.bidTimeMs, currentBid > newBid {
                return
            }
        }
        lastUpdateDate = Date()
        checkFinalStateTimer?.invalidate()
        if let userID = news.userID {
            leadFetcher = userSession.userFetcherRepo.fetcher(for: userID)
            leadFetcher?.initializeIfNeeded()
        }
        endDate = news.endDate
        self.news = news
        if let ext = news.extensionDuration {
            extensionDuration = ext
        }
    }
    
    private func reloadBidCount() {
        guard getBidCountOperation == nil else  {
            return
        }
        let op = GetMyBidCountOperation(product: product, userSession: userSession)
        op.completionBlock = {[weak self] in
            self?.didGetBidCount()
        }
        getBidCountOperation = op
        op.start()
    }
    
    private func didGetBidCount() {
        let op = getBidCountOperation!
        getBidCountOperation = nil
        if let count = op.count {
            myBid = count
        }
    }
}

class CheckBidOutcomeOperation: SimpleAsynchronousOperation {
    private(set) var outcome: BidNews?
    private(set) var isFinal = false
    
    let product: ProductOverview
    private weak var userSession: UserSession!
    private var checkOperation: GetBidNewsOperation?
    private weak var retryTimer: Timer?
    private var retryDelay = TimeInterval(1)
    
    init(product: ProductOverview, userSession: UserSession) {
        self.product = product
        self.userSession = userSession
    }
    
    override func main() {
        check()
    }
    
    private func check() {
        guard !isCancelled else {return}
        guard let session = userSession else {
            finish()
            return
        }
        let op = GetBidNewsOperation(product: product, userSession: session)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.handleCheckComplete()
            }
        }
        checkOperation = op
        op.start()
    }
    
    private func handleCheckComplete() {
        guard !isCancelled else {return}
        let op = checkOperation!
        if let news = op.news {
            checkIsFinal(from: news)
        } else {
            scheduleRetry()
        }
    }
    
    private func checkIsFinal(from news: BidNews) {
        outcome = news
        isFinal = news.endDate.timeIntervalSinceNow < 0
        finish()
    }
    
    private func scheduleRetry() {
        let timer = Timer(timeInterval: retryDelay, repeats: false) {[weak self] (_) in
            self?.check()
        }
        retryDelay *= retryDelay
        retryDelay = min(retryDelay, 60)
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        retryTimer = timer
    }
    
    override func onCancel() {
        checkOperation?.cancel()
        retryTimer?.invalidate()
    }
}

class GetMyBidCountOperation: AlamofireAPIAccessOperation {
    let product: ProductOverview
    let userSession: UserSession
    private(set) var count: Int?
    
    init(product: ProductOverview, userSession: UserSession) {
        self.product = product
        self.userSession = userSession
    }

    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("bidding/\(product.id)/bidded"), method: .head))
    }
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        if let count = header["X-Total-Count"] as? String {
            self.count = SharedNumberFormatters.integer.number(from: count)?.intValue
        }
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
}

class GetBidNewsOperation: AlamofireAPIAccessOperation {
    let product: ProductOverview
    let userSession: UserSession
    private(set) var news: BidNews?
    
    init(product: ProductOverview, userSession: UserSession) {
        self.product = product
        self.userSession = userSession
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("bidding/\(product.id)/state")))
    }
    
    override func processData(with data: Data) throws {
        news = try JSONDecoder.default.decode(BidNews.self, from: data)
    }

    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
}

class BidNews: Decodable {
    let userID: String?
    let bidTimeMs: Int?
    let endDateMs: Int
    let extensionDuration: TimeInterval?
    var endDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(endDateMs) / 1000)
    }
    
    enum CodingKeys: String, CodingKey {
        case userID = "winner"
        case bidTimeMs = "created_at"
        case endDateMs = "until"
        case extensionDuration = "extension"
    }
    
    init?(_ data: Any?) {
        guard let dict = data as? [AnyHashable: Any] else {
            return nil
        }
        endDateMs = dict[CodingKeys.endDateMs.rawValue] as! Int
        bidTimeMs =  (dict[CodingKeys.bidTimeMs.rawValue] as! Int)
        userID = (dict[CodingKeys.userID.rawValue] as! String)
        if let ext = dict[CodingKeys.extensionDuration.rawValue] as? Int {
            extensionDuration = TimeInterval(ext)
        } else {
            extensionDuration = nil
        }
    }
    
    init(userID: String, endDate: Date, bidTimeMs: Int?, extesion: TimeInterval?) {
        self.userID = userID
        self.endDateMs = Int(endDate.timeIntervalSince1970 * 1000)
        self.bidTimeMs = bidTimeMs
        extensionDuration = extesion
    }
}
