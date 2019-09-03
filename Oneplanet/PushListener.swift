//
//  PushListener.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import PusherSwift

class PushListener {
    #if DEBUG
    static let key = "6a71981de237073e6377"
    #else
    static let key = "85ab0484af04d39e9d3b"
    #endif
    
    let pusher: Pusher
    
    init() {
        let opt = PusherClientOptions(host: .cluster("ap3"))
        pusher = Pusher(key: PushListener.key, options: opt)
        pusher.connect()
    }
    
    deinit {
        pusher.disconnect()
    }
}
