//
//  WeChatLogIn.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/2.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks

class WeChatLogInOperation: SimpleAsynchronousOperation, SocialAuthenticationOperationType, WXApiDelegate {
    static weak var runningLogIn: WeChatLogInOperation?
    
    private(set) var success: Bool?
    private(set) var error: Error?
    private(set) var token: String?
    private(set) var profile: MyProfile?
    private(set) var publicProfile: PublicProfile?
    private var authReq: SendAuthReq?
    private var state = UUID().uuidString
    private var submitCodeOperation: SubmitWeChatAuthCodeOperation?
    
    let presenter: UIViewController
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    override func main() {
        let req = SendAuthReq()
        req.openID = "wxc34b2b654e956933"
        req.scope = "snsapi_userinfo"
        req.state = state
        authReq = req
        WeChatLogInOperation.runningLogIn = self
        WXApi.send(req)
//        if WXApi.isWXAppSupport() {
//            WXApi.send(req)
//        } else {
//            WXApi.sendAuthReq(req, viewController: presenter, delegate: self)
//        }
    }
    
    func onResp(_ resp: BaseResp!) {
        guard let res = resp as? SendAuthResp,
            res.errCode == 0,
            let code = res.code else {
                fail(with: nil)
                return
        }
        if res.state != state {
            logger.warning("Untrusted response \(res)")
            fail(with: nil)
            return
        }
        submitAuthCode(code)
    }
    
    private func submitAuthCode(_ code: String) {
        let op = SubmitWeChatAuthCodeOperation(authCode: code)
        op.completionBlock = {[weak self] in
            self?.didGetToken()
        }
        submitCodeOperation = op
        op.start()
    }
    
    private func didGetToken() {
        let op = submitCodeOperation!
        guard let token = op.token,
            let session = op.wechatSession else {
            return
        }
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
    }
}

class GetWeChatProfileOperation: AlamofireAPIAccessOperation {
    let wechatSession: WeChatSession
    init(wechatSession: WeChatSession) {
        self.wechatSession = wechatSession
    }
}

class SubmitWeChatAuthCodeOperation: LogInOperation {
    let authCode: String
    private(set) var wechatSession: WeChatSession?
    init(authCode: String) {
        self.authCode = authCode
    }
}

class WeChatSession {
    let token: String = ""
    let openID: String = ""
}
