//
//  BidPhaseIndicator.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/11.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class BidPhaseIndicator {
    var phase: Phase {
        didSet {
            if oldValue != phase {
                updateObservers.invokeEach{$0()}
            }
        }
    }
    let updateObservers = MulticastCallbackNode<()->()>()
    private(set) var bidStartDate: Date
    private(set) var bidEndDate: Date
    private(set) var sessionEndDate: Date
    let bidProcessManager: ProductBidProcessManager
    private var refreshTimer: Timer?
    private var refreshOperation: GetBidSessionTimeframeOperation?
    private var updateClock: UpdateClock!
    var biddingHasStarted: Bool {
        return phase != .unlock
    }
    init(sessionTimeframe: SessionTimeframe, bidProcessManager: ProductBidProcessManager) {
        self.bidProcessManager = bidProcessManager
        bidStartDate = sessionTimeframe.bidStart
        bidEndDate = sessionTimeframe.bidEnd
        sessionEndDate = sessionTimeframe.end
        phase = .unlock
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updatePhaseIfNeeded()
        })
        updatePhaseIfNeeded()
    }
    
    func update(with timeframe: SessionTimeframe) {
        guard timeframe.bidStart != bidStartDate else {
            return
        }
        bidStartDate = timeframe.bidStart
        bidEndDate = timeframe.bidEnd
        if bidStartDate.timeIntervalSinceNow > 0 {
            refreshTimer?.invalidate()
            phase = .unlock
        }
    }
    
    private func updatePhaseIfNeeded() {
        guard phase != .ended else {
            setUpRefreshTimerIfNeeded()
            return
        }
        refreshTimer?.invalidate()
        refreshOperation?.cancel()
        refreshOperation = nil
        if bidStartDate.timeIntervalSinceNow > 0 {
            phase = .unlock
        } else {
            if bidEndDate.timeIntervalSinceNow < 0 {
                phase = .ended
            } else if bidProcessManager.isEnded {
                phase = .spectator
            } else {
                phase = .running
            }
        }
    }
    
    private func setUpRefreshTimerIfNeeded() {
        guard refreshTimer == nil
            && sessionEndDate.timeIntervalSinceNow < 0 else {
            return
        }
        let timer = Timer(timeInterval: 10 * .minute, repeats: true) {[weak self] (_) in
            self?.refreshIfNeeded()
        }
        timer.tolerance = 1
        refreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        refreshIfNeeded()
    }
    
    func refreshIfNeeded() {
        guard refreshOperation == nil else {
            return
        }
        let op = GetBidSessionTimeframeOperation()
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didRefresh()
            }
        }
        refreshOperation = op
        op.start()
    }
    
    private func didRefresh() {
        let op = refreshOperation!
        refreshOperation = nil
        if let tf = op.timeframe {
            update(with: tf)
        }
    }
}

extension BidPhaseIndicator {
    enum Phase {
        case unlock
        case running
        case spectator
        case ended
    }
}

class GetBidSessionTimeframeOperation: AlamofireAPIAccessOperation {
    private(set) var timeframe: SessionTimeframe?
    
    override func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: ServiceURLs.base.appendingPathComponent("bidding/schedule_time"))
    }
    
    override func processData(with data: Data) throws {
        guard !data.isEmpty && timeframe == nil else {return}
        timeframe = try JSONDecoder.default.decode(SessionTimeframe.self, from: data)
    }
    
    override func handleClientError(with response: HTTPURLResponse) throws {
        if response.statusCode == 404 {
            timeframe = SessionTimeframe(bidStart: Date(), bidEnd: Date(), end: Date())
        } else {
            try super.handleClientError(with: response)
        }
    }
}

struct SessionTimeframe: Decodable {
    let bidStart: Date
    let bidEnd: Date
    let end: Date
    
    enum CodingKeys: String, CodingKey {
        case bidStart = "start_bid_at"
        case bidEnd = "close_bid_at"
        case end = "close_at"
    }
}
