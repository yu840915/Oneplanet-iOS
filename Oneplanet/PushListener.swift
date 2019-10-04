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
    #if DEBUG
    static let key = "85ab0484af04d39e9d3b"
//    static let key = "72a9204d5eb8a13b6fa2"
    #else
    static let key = "85ab0484af04d39e9d3b"
    #endif
    
    let pusher: Pusher
    
    init(session: UserSession) {
        let builder = AuthRequestBuilder(session: session)
        let opt = PusherClientOptions(authMethod: AuthMethod.authRequestBuilder(authRequestBuilder: builder), host: .cluster("ap3"))
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

class AuthRequestBuilder: AuthRequestBuilderProtocol {
    private weak var session: UserSession?
    init(session: UserSession) {
        self.session = session
    }
    
    func requestFor(socketID: String, channelName: String) -> URLRequest? {
        var req = URLRequest(url: ServiceURLs.base.appendingPathComponent("pusher/auth"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let info = ChannelInfo(socketID: socketID, channelName: channelName)
        req.httpBody = try? JSONEncoder().encode(info)
        return session?.addingAuthorizationToken(to: req)
    }
}

extension AuthRequestBuilder {
    class ChannelInfo: Encodable {
        let socketID: String
        let channelName: String
        
        init(socketID: String, channelName: String) {
            self.socketID = socketID
            self.channelName = channelName
        }
    }
}

class PushChannel {
    let channel: PusherChannel
    let pusher: Pusher
    var isConnected: Bool {
        guard let connection = channel.connection else {
            return false
        }
        return connection.connectionState == .connected
    }
    
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
