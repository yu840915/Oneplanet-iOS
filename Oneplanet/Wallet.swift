//
//  Wallet.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import Alamofire
import ModelBlocks
import UIKit

class Wallet {
    let updateObservers = MulticastCallbackNode<()->()>()
    var blueGem: Balance { return balance(for: .blueGem) }
    var purpleGem: Balance { return balance(for: .purpleGem) }
    var greenGem: Balance { return balance(for: .greenGem) }
    var score: Balance { return balance(for: .score) }
    var isFullyInitialized: Bool {
        return !balances.map{$0.value}.contains{!$0.isInitialized}
    }
    
    private var updateInvoker: UpdateClock!
    private let balances: [BalanceAccount: Balance]
    init(userSession: UserSession) {
        var map = [BalanceAccount: Balance]()
        let accounts: [BalanceAccount] = [.blueGem, .greenGem, .purpleGem, .score]
        accounts.forEach{
            map[$0] = Balance(account: $0, userSession: userSession)
        }
        balances = map
        map.forEach{
            $0.value.updateHandler = {[weak self] in
                self?.notifyUpdate()
            }
        }
        updateInvoker = UpdateClock(preferredFrameRate: 2, onTick: {[weak self] in
            self?.updateIfNeeded()
        })
        setNeedsUpdate()
    }
    
    func setNeedsUpdate() {
        balances.forEach{
            $0.value.setNeedsRefresh()
        }
    }
    
    func setNeedsUpdateBalance(for account: BalanceAccount) {
        balance(for: account).setNeedsRefresh()
    }
    
    func setNeedsUpdateBlueGem() {
        setNeedsUpdateBalance(for: .blueGem)
        setNeedsUpdateBalance(for: .score)
    }

    func setNeedsUpdatePurpleGem() {
        setNeedsUpdateBalance(for: .purpleGem)
    }

    func setNeedsUpdateGreenGem() {
        setNeedsUpdateBalance(for: .greenGem)
    }

    func balance(for account: BalanceAccount) -> Balance {
        return balances[account]!
    }
    
    private func updateIfNeeded() {
        balances.forEach{$0.value.refreshIfNeeded()}
    }
    
    private func notifyUpdate() {
        updateObservers.invokeEach{$0()}
    }
}

class Balance {
    private(set) weak var userSession: UserSession!
    let account: BalanceAccount
    var updateHandler: (()->())?
    private(set) var isInitialized = false
    private(set) var total: Int = 0 {
        didSet {
            if oldValue != total {
                updateHandler?()
            }
        }
    }
    private(set) var needsRefresh = false
    private var refreshOperation: GetBalanceOperation?
    private(set) var lastUpdateDate = Date()
    private var isOutdated: Bool {
        return lastUpdateDate.timeIntervalSinceNow.magnitude > 10 * .minute
    }
    
    init(account: BalanceAccount, userSession: UserSession) {
        self.userSession = userSession
        self.account = account
    }
    
    deinit {
        refreshOperation?.cancel()
    }
    
    func setNeedsRefresh() {
        needsRefresh = true
    }
    
    func refreshIfNeeded() {
        guard (isOutdated || needsRefresh) && refreshOperation == nil else { return }
        needsRefresh = false
        refresh()
    }
    
    private func refresh() {
        let op = GetBalanceOperation(account: account, userSession: userSession)
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
        if let total = op.total {
            isInitialized = true
            self.total = total
            lastUpdateDate = Date()
        } else {
            logger.error("Cannot refresh balance: \(account)", context: op.error)
        }
    }
}

enum BalanceAccount: String, Decodable {
    case blueGem = "blue_diamond"
    case purpleGem = "red_diamond"
    case greenGem = "green_diamond"
    case score = "exp"
    
    var displayName: String {
        switch self {
        case .blueGem: return Localized.titles.blueGem
        case .greenGem: return Localized.titles.greenGem
        case .purpleGem: return Localized.titles.purpleGem
        case .score: return "Exp"
        }
    }
}

class GetBalanceOperation: AlamofireAPIAccessOperation {
    let userSession: UserSession
    let account: BalanceAccount
    init(account: BalanceAccount, userSession: UserSession) {
        self.account = account
        self.userSession = userSession
    }
    private(set) var total: Int?
    
    override func prepareURLRequest() throws -> URLRequest {
        return userSession.addingAuthorizationToken(to: URLRequest(url: ServiceURLs.devBase.appendingPathComponent("wallet/balance/\(account.rawValue)")))
    }
    
    override func processData(with data: Data) throws {
        total = (try JSONDecoder.default.decode(Total.self, from: data)).total
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        userSession.deactivate()
    }
    
    struct Total: Decodable {
        let total: Int
    }
}


enum Currency {
    case blueGem
    case purpleGem
    case greenGem
}

extension Currency {
    var apiName: String {
        switch self {
        case .blueGem: return "blue_diamond"
        case .purpleGem: return "red_diamond"
        case .greenGem: return "green_diamond"
        }
    }
    
    var largeIcon: UIImage {
        switch self {
        case .blueGem: return #imageLiteral(resourceName: "ic_gem80_nor")
        case .purpleGem: return #imageLiteral(resourceName: "ic_coin80_nor")
        case .greenGem: return #imageLiteral(resourceName: "ic_key80_nor")
        }
    }
    
    var displayName: String {
        switch self {
        case .blueGem: return Localized.titles.blueGem
        case .purpleGem: return Localized.titles.purpleGem
        case .greenGem: return Localized.titles.greenGem
        }
    }
}
