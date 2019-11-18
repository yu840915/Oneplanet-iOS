//
//  BonusEvent.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/28.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class BonusEventRepository {
    let userSession: UserSession
    private var events: [String: BonusEvent] = [:]
    
    init(userSession: UserSession) {
        self.userSession = userSession
    }
    
    func event(for id: String) -> BonusEvent {
        if let e = events[id] {
            e.initializeIfNeeded()
            return e
        }
        let e = BonusEvent(id: id, userSession: userSession)
        events[id] = e
        e.initializeIfNeeded()
        return e
    }
}

class BonusEvent {
    let id: String
    let userSession: UserSession
    private(set) var isRedeemed: Bool = false
    private(set) var info: BonusEventInfo?
    private var getInfoOperation: GetBonusEventInfoOperation?
    private var redeemOperation: RedeemBonusEventOperation?
    
    init(id: String, userSession: UserSession) {
        self.id = id
        self.userSession = userSession
    }
    
    deinit {
        getInfoOperation?.cancel()
        redeemOperation?.cancel()
    }
    
    func initializeIfNeeded() {
        guard info == nil && getInfoOperation == nil else { return }
        let op = GetBonusEventInfoOperation(id: id, userSession: userSession)
        op.completionBlock = {[weak self] in
            self?.didGetInfo()
        }
        getInfoOperation = op
        op.start()
    }
    
    private func didGetInfo() {
        let op = getInfoOperation!
        getInfoOperation = nil
        if let info = op.info {
            self.info = info
            isRedeemed = info.isRedeemed
        }
    }
    
    func redeemIfAllowed(completion: ((Bool, Error?)->())?) {
        guard info != nil && !isRedeemed && redeemOperation == nil else {
            completion?(isRedeemed, nil)
            return
        }
        let op = RedeemBonusEventOperation(id: id, userSession: userSession)
        op.completionBlock = {[weak self] in
            self?.didRedeem(completion: completion)
        }
        redeemOperation = op
        op.start()
    }
    
    private func didRedeem(completion: ((Bool, Error?)->())?) {
        let op = redeemOperation!
        redeemOperation = nil
        if op.success == true {
            isRedeemed = true
            completion?(true, nil)
            userSession.wallet.setNeedsUpdateBalance(for: info!.currency)
        } else {
            completion?(false, op.error)
        }
    }
}

class GetBonusEventInfoOperation: AlamofireAPIAccessOperation {
    let id: String
    let userSession: UserSession
    private(set) var info: BonusEventInfo?
    
    init(id: String, userSession: UserSession) {
        self.id = id
        self.userSession = userSession
    }

    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.base.appendingPathComponent("events/\(id)")))
    }
    
    override func processData(with data: Data) throws {
        info = try JSONDecoder.default.decode(BonusEventInfo.self, from: data)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
}

class RedeemBonusEventOperation: AlamofireAPIAccessOperation {
    let id: String
    let userSession: UserSession

    init(id: String, userSession: UserSession) {
        self.id = id
        self.userSession = userSession
    }

    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: try URLRequest(url: ServiceURLs.base.appendingPathComponent("events/bonus/redeem/\(id)"), method: .put))
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
}

class BonusEventInfo: Decodable {
    let name: String?
    let isRedeemed: Bool
    let currency: BalanceAccount
    let amount: Int
    let senderID: String
    
    var type: BonusEventType {
        if let name = self.name {
            return BonusEventType(rawValue: name) ?? .gift
        }
        return .gift
    }
    
    enum CodingKeys: String, CodingKey {
        case name, currency, amount
        case senderID = "sender"
        case isRedeemed = "redeemed"
    }
}

enum BonusEventType: String, Decodable {
    case likePost = "favorite_post"
    case gift = "free_bonus_reward"
    case loginReward = "login_reward"
}
