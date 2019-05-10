//
//  URLRouter.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/4/29.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import JLRoutes

let router: DelayURLRouter = DelayURLRouter(JLRoutes.global())

class URLRouter {
    let router: JLRoutes
    init(_ router: JLRoutes = JLRoutes()) {
        self.router = router
    }
    private(set) var overridingRouters: [URLRouter] = []
    
    func add(_ pattern: String, handler: @escaping ([String: Any])-> Bool) {
        router.addRoute(pattern, handler: handler)
    }
    
    func remove(_ pattern: String) {
        router.removeRoute(withPattern: pattern)
    }
    
    @discardableResult func handle(_ url: URL) -> Bool {
        if overridingRouters.reversed().contains(where: { return $0.handle(url) }) {
            return true
        }
        return router.routeURL(url)
    }
    
    func addOverridingRouter(_ router: URLRouter) {
        if router === self || overridingRouters.contains(where: { $0 === router }) {
            return
        }
        overridingRouters.append(router)
    }
    
    func removeOverridingRouter(_ router: URLRouter) {
        overridingRouters = overridingRouters.filter{$0 !== router}
    }
}

extension URLRouter {
    struct Keys {
        private init() {}
        static let url = JLRouteURLKey
    }
}

class DelayURLRouter: URLRouter {
    /*
     This one provides just-enough implementation of delayed routing, i.e., just stacks routing requests without querying handling capability.
     */
    private var waitingURLs: [URL] = []
    private(set) var isActive = false
    
    @discardableResult override func handle(_ url: URL) -> Bool {
        if !isActive {
            waitingURLs.append(url)
            return false
        } else {
            return super.handle(url)
        }
    }
    
    func resume() {
        guard !isActive else { return }
        isActive = true
        waitingURLs.forEach{handle($0)}
    }
}

