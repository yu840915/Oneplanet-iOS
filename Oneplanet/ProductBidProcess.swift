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
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func process(for product: ProductOverview) -> ProductBidProcess {
        if let process = processes[product.id] {
            return process
        }
        let process = ProductBidProcess(product: product, pushListener: pushListener, userSession: userSession)
        processes[product.id] = process
        return process
    }
}

class ProductBidProcess: Equatable {
    static func == (lhs: ProductBidProcess, rhs: ProductBidProcess) -> Bool {
        return lhs.product.id == rhs.product.id
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
    private var newsChannel: PushChannel!
    private var chennelID: Any!
    var lead: User? {
        return leadFetcher?.user
    }
    var isEnded: Bool {
        if let date = endDate {
            return date.timeIntervalSinceNow <= -5
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
    
    init(product: ProductOverview, pushListener: PushListener, userSession: UserSession) {
        self.product = product
        self.pushListener = pushListener
        self.userSession = userSession
        getNews()
        prepareChannel()
        reloadBidCount()
    }
    
    func checkFinalStateIfNeeded() {
        guard let date = endDate, date.timeIntervalSinceNow < 0, date.timeIntervalSinceNow > -1 else {
            return
        }
        guard checkFinalStateTimer == nil && getBidCountOperation == nil else {
            return
        }
        if !isWinning { return }
        let timer = Timer(timeInterval: 0.5, repeats: false) {[weak self] (_) in
            self?.getNews()
        }
        timer.tolerance = 0.1
        RunLoop.main.add(timer, forMode: .common)
        checkFinalStateTimer = timer
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
    
    private func prepareChannel() {
        let channel = pushListener.subscribeChannel(ofName: product.id)
        chennelID = channel.addEventHandler(for: "bid") {[weak self] (data) in
            OperationQueue.main.addOperation {
                self?.handleBidEvent(data)
            }
        }
        newsChannel = channel
    }
    
    private func didGetNews() {
        let op = getNewsOperation!
        getNewsOperation = nil
        if let news = op.news {
            update(with: news)
        }
    }
    
    private func handleBidEvent(_ data: Any?) {
        if let news = BidNews(data) {
            update(with: news)
        }
    }
    
    private func update(with news: BidNews) {
        checkFinalStateTimer?.invalidate()
        if let userID = news.userID {
            leadFetcher = userSession.userFetcherRepo.fetcher(for: userID)
            leadFetcher?.initializeIfNeeded()
        }
        endDate = news.endDate
        self.news = news
        if userSession.isAdmin || userSession.profile?.id == news.userID {
            reloadBidCount()
        }
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
        return userSession.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.devBase.appendingPathComponent("bidding/\(product.id)/state")))
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
    let endDate: Date
    let extensionDuration: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case userID = "winner"
        case endDate = "until"
        case extensionDuration = "extension"
    }
    
    init?(_ data: Any?) {
        guard let dict = data as? [AnyHashable: Any] else {
            return nil
        }
        var date: Date?
        if let ts = dict[CodingKeys.endDate.rawValue] as? Int {
            date = Date(timeIntervalSince1970: TimeInterval(ts))
        } else if let dtStr = dict[CodingKeys.endDate.rawValue] as? String {
            date = SharedDateFormatters.serverDate.date(from: dtStr)
        }
        guard let dt = date,
            let id = dict[CodingKeys.userID.rawValue] as? String else {
                return nil
        }
        endDate = dt
        userID = id
        if let ext = dict[CodingKeys.extensionDuration.rawValue] as? Int {
            extensionDuration = TimeInterval(ext)
        } else {
            extensionDuration = nil
        }
    }
    
    init(userID: String, endDate: Date, extesion: TimeInterval?) {
        self.userID = userID
        self.endDate = endDate
        extensionDuration = extesion
    }
}
