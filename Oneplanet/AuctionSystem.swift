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

class UnlockProductOperation: AlamofireAPIAccessOperation {
    let product: ProductOverview
    let session: UserSession
    let currency: Currency

    init(product: ProductOverview, session: UserSession, currency: Currency) {
        self.product = product
        self.session = session
        self.currency = currency
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        let dict: [String: String] = ["currency": currency.apiName]
        let url = ServiceURLs.devBase.appendingPathComponent("products/\(product.id)/unlock")
        return Alamofire.request(url, method: .post, parameters: dict, encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    override func willFinishProcess() throws {
        session.lotList.reload()
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
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
        let dict: [String: String] = ["currency": currency.apiName]
        let url = ServiceURLs.devBase.appendingPathComponent("bidding/\(product.id)")
        return Alamofire.request(url, method: .post, parameters: dict, encoding: JSONEncoding.default, headers: session.authorizationHeader)
    }
    
    override func handleUnauthorizedError(with response: HTTPURLResponse) throws {
        session.deactivate()
    }
}
