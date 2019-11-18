//
//  WeChatLogIn.swift
//  Oneplanet
//
//  Created by 立宣于 on 2019/5/2.
//  Copyright © 2019 何一品居. All rights reserved.
//

import Foundation
import ModelBlocks
import UIKit
import Alamofire

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
    private var getProfileOperation: GetWeChatProfileOperation?
    
    let presenter: UIViewController
    init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    override func main() {
        let req = SendAuthReq()
        req.scope = "snsapi_userinfo"
        req.state = state
        authReq = req
        WeChatLogInOperation.runningLogIn = self
        WXApi.send(req)
        if WXApi.isWXAppSupport() {
            WXApi.send(req)
        } else {
            WXApi.sendAuthReq(req, viewController: presenter, delegate: self)
        }
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
        debugPrint("[Wechat] code \(code)")
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
            let profile = op.profile else {
                fail(with: nil)
                return
        }
        self.token = token
        self.profile = profile
        if let session = op.wechatSession {
            getWeChatProfile(with: session)
        } else {
            success = true
            finish()
        }
    }
    
    private func getWeChatProfile(with session: WeChatSession) {
        let op = GetWeChatProfileOperation(wechatSession: session)
        op.completionBlock = {[weak self] in
            self?.didGetWeChatProfile()
        }
        getProfileOperation = op
        op.start()
    }
    
    private func didGetWeChatProfile() {
        let op = getProfileOperation!
        publicProfile = op.profile
        success = true
        finish()
    }
    
    private func fail(with error: Error?) {
        success = false
        self.error = error
        finish()
    }
}

class GetWeChatProfileOperation: AlamofireAPIAccessOperation {
    let wechatSession: WeChatSession
    private(set) var profile: PublicProfile?

    init(wechatSession: WeChatSession) {
        self.wechatSession = wechatSession
    }
    
    override func prepareDataRequest() throws -> DataRequest {
        let url = URL(string: "https://api.weixin.qq.com/sns/userinfo")!
        let params: Parameters = ["access_token": wechatSession.token, "openid": wechatSession.openID]
        return Alamofire.request(url, method: .get, parameters: params, encoding: URLEncoding(), headers: nil)
    }
    
    override func processData(with data: Data) throws {
        let wechatProfile = try JSONDecoder.default.decode(WeChatProfile.self, from: data)
        var url: URL?
        if let avatar = wechatProfile.headimgurl {
            url = URL(string: avatar)
        }
        profile = PublicProfile(nickname: wechatProfile.nickname, avatarURL: url)
    }
}

class SubmitWeChatAuthCodeOperation: LogInOperation {
    let authCode: String
    private(set) var wechatSession: WeChatSession?
    init(authCode: String) {
        self.authCode = authCode
    }
    
    override func prepareURLRequest() throws -> URLRequest {
        var comp = URLComponents(url: ServiceURLs.base.appendingPathComponent("login/weixinapp"), resolvingAgainstBaseURL: false)!
        comp.queryItems = [.init(name: "code", value: authCode)]
        return try URLRequest(url: comp.url!, method: .post)
    }
    
    override func processHTTPResponseHeader(_ header: [AnyHashable : Any]) throws {
        try super.processHTTPResponseHeader(header)
        if let token = header["X-Weixin-Token"] as? String,
            let id = header["X-Weixin-Openid"] as? String {
            wechatSession = WeChatSession(token: token, openID: id)
        }
    }
}

class WeChatSession {
    let token: String
    let openID: String
    
    init(token: String, openID: String) {
        self.token = token
        self.openID = openID
    }
}

class WeChatProfile: Decodable {
    let nickname: String
    let headimgurl: String?
}
