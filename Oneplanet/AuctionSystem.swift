//
//  AuctionSystem.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class MyLotList: PaginatedList<GetMyLotPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetMyLotPageOperationFactory(session: session))
    }
}

class GetMyLotPageOperationFactory: PaginatedFetchingOperationFactoryType {
    private weak var session: UserSession!
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetMyLotPageOperation {
        return GetMyLotPageOperation(session: session)
    }
}

class GetMyLotPageOperation: AlamofireAPIAccessOperation, PaginatedFetchingOperationType, ListingType {
    let isBeginning: Bool
    private(set) var nextPageFetchingOperation: PaginatedFetchingOperationType?
    var retryOperation: PaginatedFetchingOperationType? {
        return GetMyLotPageOperation(session: session, url: url, isBeginning: isBeginning)
    }
    private(set) var items: [ProductOverview] = []
    let session: UserSession
    private let url: URL
    
    convenience init(session: UserSession) {
        var comp = URLComponents(url: ServiceURLs.devBase.appendingPathComponent("products"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [.init(name: "category", value: "shoes")]
        self.init(session: session, url: comp.url!, isBeginning: true)
    }
    
    init(session: UserSession, url: URL, isBeginning: Bool) {
        self.isBeginning = isBeginning
        self.session = session
        self.url = url
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return session.addingAuthorizationToken(to: URLRequest(url: url))
    }
    
    override func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        try super.handleHTTPResponse(response)
        prepareNextPage(from: response)
    }
    
    private func prepareNextPage(from response: HTTPURLResponse) {
        let finder = WebLinkingKeyMap(links: response.links)
        guard let url = finder.findLink(in: response, for: PageRelation.next) else  {
            return
        }
        nextPageFetchingOperation = GetMyLotPageOperation(session: session, url: url, isBeginning: false)
    }
    
    override func processData(with data: Data) throws {
        items = try JSONDecoder.default.decode([ProductOverview].self, from: data)
    }
}

class BidProductOperation: AlamofireAPIAccessOperation {
    let product: ProductOverview
    let session: UserSession
    let currency: Currency
    
    init(product: ProductOverview, session: UserSession, currency: Currency) {
        self.product = product
        self.session = session
        self.currency = currency
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        let dict: [String: String] = ["user_id": session.profile!.id]
        let url = ServiceURLs.devBase.appendingPathComponent("bidding/\(product.id)")
        return Alamofire.request(url, method: .post, parameters: dict, encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
}

class BidProcessManager {
    lazy var pushListener: PushListener = PushListener()
    private weak var userSession: UserSession!
    private var processes: [String: BidProcess] = [:]
    var isEnded: Bool {
        return !processes.contains{$0.value.isEnded == false}
    }
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func process(for product: ProductOverview) -> BidProcess {
        if let process = processes[product.id] {
            return process
        }
        let process = BidProcess(product: product, pushListener: pushListener, userSession: userSession)
        processes[product.id] = process
        return process
    }
}

class BidProcess {
    let product: ProductOverview
    let userSession: UserSession
    let pushListener: PushListener
    var isInitialized: Bool {
        return news != nil
    }
    private var news: BidNews?
    private var getNewsOperation: GetBidNewsOperation?
    private var newsChannel: PushChannel!
    private var chennelID: Any!
    var lead: User? {
        return leadFetcher?.user
    }
    var isEnded: Bool {
        if let date = endDate {
            return date.timeIntervalSinceNow <= 0
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
    
    init(product: ProductOverview, pushListener: PushListener, userSession: UserSession) {
        self.product = product
        self.pushListener = pushListener
        self.userSession = userSession
        getNews()
        prepareChannel()
    }
    
    private func getNews() {
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
        leadFetcher = userSession.userFetcherRepo.fetcher(for: news.userID)
        endDate = news.endDate
        self.news = news
        if userSession.isAdmin || userSession.profile?.id == news.userID {
            reloadBidCount()
        }
    }
    
    private func reloadBidCount() {
        
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
}

class BidNews: Decodable {
    let userID: String
    let endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case userID = "winner"
        case endDate = "until"
    }
    
    init?(_ data: Any?) {
        guard let dict = data as? [AnyHashable: Any] else {
            return nil
        }
        guard let ts = dict[CodingKeys.endDate.rawValue] as? Int,
            let id = dict[CodingKeys.userID.rawValue] as? String else {
            return nil
        }
        endDate = Date(timeIntervalSince1970: TimeInterval(ts))
        userID = id
    }
    
    init(userID: String, endDate: Date) {
        self.userID = userID
        self.endDate = endDate
    }
}
