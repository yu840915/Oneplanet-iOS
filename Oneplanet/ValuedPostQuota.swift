//
//  ValuedPostQuota.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/16.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class ValuedPostQuota {
    let userSession: UserSession
    private(set) var lastState: ValuedPostQuotaState?
    private var getStateOperation: GetValuedPostQuotaStateOperation?
    private var updateClock: UpdateClock!
    
    init(userSession: UserSession) {
        self.userSession = userSession
        updateClock = UpdateClock(preferredFrameRate: 5, onTick: {[weak self] in
            self?.refreshIfChargeDateDued()
        })
    }
    
    private func refreshIfChargeDateDued() {
        if let state = lastState {
            if state.isChargeDateDued {
                refresh()
            }
        } else {
            refresh()
        }
    }
    
    func refresh() {
        guard getStateOperation == nil else { return }
        let op = GetValuedPostQuotaStateOperation(userSession: userSession)
        op.completionBlock = {[weak self] in
            OperationQueue.main.addOperation {
                self?.didGetState()
            }
        }
        getStateOperation = op
        op.start()
    }
    
    private func didGetState() {
        let op = getStateOperation!
        getStateOperation = nil
        if let state = op.state {
            lastState = state
        }
    }
}

class GetValuedPostQuotaStateOperation: AlamofireAPIAccessOperation {
    let userSession: UserSession
    private(set) var state: ValuedPostQuotaState?
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("posts/quota/state")))
    }
    
    override func processData(with data: Data) throws {
        state = try JSONDecoder.default.decode(ValuedPostQuotaState.self, from: data)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
}

struct ValuedPostQuotaState: Decodable {
    let quota: Int
    let used: Int
    var isFull: Bool {
        return remain == quota
    }
    var remain: Int {
        let value = max(quota - used, 0)
        return min(isChargeDateDued ? value + 1 : value, quota)
    }
    let nextChargeDate: Date?
    var isChargeDateDued: Bool {
        if used == 0 {
            return false
        }
        if let date = nextChargeDate {
            return date.timeIntervalSinceNow < 0
        }
        return false
    }
    
    enum CodingKeys: String, CodingKey {
        case quota, used
        case nextChargeDate = "allow_post_at"
    }
}
