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
    let startDate: Date = Date(timeIntervalSinceNow: 10 * .minute)
    let bidProcessManager: BidProcessManager
    private var updateClock: UpdateClock!
    var biddingHasStarted: Bool {
        return phase != .unlock
    }
    init(currentPhase: Phase, bidProcessManager: BidProcessManager) {
        self.bidProcessManager = bidProcessManager
        phase = currentPhase
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.updatePhaseIfNeeded()
        })
    }
    
    func updateStartDate(_ date: Date) {
        guard date != startDate else {
            return
        }
        if date.timeIntervalSinceNow > 0 {
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
            if bidProcessManager.isEnded {
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
