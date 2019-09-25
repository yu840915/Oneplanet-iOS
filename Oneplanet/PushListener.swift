//
//  PushListener.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/8/3.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import PusherSwift
import ModelBlocks

class PushListener {
    static let key = "72a9204d5eb8a13b6fa2"
//    #if DEBUG
//    static let key = "72a9204d5eb8a13b6fa2"
//    #else
//    static let key = "85ab0484af04d39e9d3b"
//    #endif
    
    let pusher: Pusher
    
    init() {
        let opt = PusherClientOptions(host: .cluster("ap3"))
        pusher = Pusher(key: PushListener.key, options: opt)
        pusher.connect()
    }
    
    func subscribeChannel(ofName name: String) -> PushChannel {
        return PushChannel(channel: pusher.subscribe(name), pusher: pusher)
    }
    
    deinit {
        pusher.disconnect()
    }
}

class PushChannel {
    let channel: PusherChannel
    let pusher: Pusher
    
    init(channel: PusherChannel, pusher: Pusher) {
        self.channel = channel
        self.pusher = pusher
    }
    
    func addEventHandler(for event: String, handler: @escaping (Any?)->()) -> Any {
        return channel.bind(eventName: event, callback: handler)
    }
    
    deinit {
        pusher.unsubscribe(channel.name)
    }
}
