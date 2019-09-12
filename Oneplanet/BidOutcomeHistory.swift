//
//  BidOutcomeHistory.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/9/12.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import Alamofire

class BidOutcomeHistory: PaginatedList<GetBidOutcomeHistoryPageOperationFactory> {
    init(session: UserSession) {
        super.init(operationFactory: GetBidOutcomeHistoryPageOperationFactory(session: session))
    }
}

class GetBidOutcomeHistoryPageOperationFactory: PaginatedFetchingOperationFactoryType {
    let session: UserSession
    init(session: UserSession) {
        self.session = session
    }
    
    func makeInitialOperation() -> GetProductCagegoryPageOperation {
        let url = ServiceURLs.devBase.appendingPathComponent("bidding/history").addingFirstPageQeury()
        return GetProductCagegoryPageOperation(session: session, url: url, isBeginning: true)
    }
}
