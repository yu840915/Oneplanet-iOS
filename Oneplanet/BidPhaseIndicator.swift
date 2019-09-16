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
    private(set) var startDate: Date
    private(set) var endDate: Date
    let bidProcessManager: ProductBidProcessManager
    private var updateClock: UpdateClock!
    var biddingHasStarted: Bool {
        return phase != .unlock
    }
    init(sessionTimeframe: SessionTimeframe, bidProcessManager: ProductBidProcessManager) {
        self.bidProcessManager = bidProcessManager
        startDate = sessionTimeframe.start
        endDate = sessionTimeframe.end
        phase = .unlock
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updatePhaseIfNeeded()
        })
        updatePhaseIfNeeded()
    }
    
    func update(with timeframe: SessionTimeframe) {
        guard timeframe.start != startDate else {
            return
        }
        startDate = timeframe.start
        endDate = timeframe.end
        if startDate.timeIntervalSinceNow > 0 {
            phase = .unlock
        }
    }
    
    private func updatePhaseIfNeeded() {
        guard phase != .ended else {
            return
        }
        if startDate.timeIntervalSinceNow > 0 {
            phase = .unlock
        } else {
            if endDate.timeIntervalSinceNow < 0 {
                phase = .ended
            } else if bidProcessManager.isEnded {
                phase = .spectator
            } else {
                phase = .running
            }
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
        timeframe = try JSONDecoder.default.decode(SessionTimeframe.self, from: data)
    }
}

struct SessionTimeframe: Decodable {
    let start: Date
    let end: Date
    
    enum CodingKeys: String, CodingKey {
        case start = "start_bid_at"
        case end = "close_bid_at"
    }
}
