import Foundation
import ModelBlocks
import Alamofire

class AlamofireAPIAccessOperation: SimpleAsynchronousOperation, FailableOperationType {
    private(set) var success: Bool?
    private(set) var error: Error?
    
    private var dataRequest: Alamofire.DataRequest?
    private(set) var httpResponse: HTTPURLResponse?
    
    override func main() {
        guard !isCancelled else { return }
        do {
            dataRequest = try prepareDataRequest().response(completionHandler: {[weak self] (res) in
                self?.processDataResponse(res)
            })
        } catch let error {
            errorOut(with: error)
        }
    }
    
    open func prepareDataRequest() throws -> Alamofire.DataRequest {
        return Alamofire.request(try prepareURLRequest())
    }
    
    open func prepareURLRequest() throws -> URLRequest {
        return URLRequest(url: URL(string: "https://domain")!)
    }
    
    private func processDataResponse(_ dataResponse: DefaultDataResponse) {
        guard !isCancelled else { return }
        guard let httpResponse = dataResponse.response else {
            if let error = dataResponse.error {
                errorOut(with: error)
            } else {
                success = false
            }
            return
        }
        self.httpResponse = httpResponse
        do {
            try handleHTTPResponse(httpResponse)
            if let data = dataResponse.data {
                try processData(with: data)
            }
            try willFinishProcess()
            success = true
            finish()
        } catch let error {
            errorOut(with: error)
        }
    }
    
    open func handleHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299, 300...399: try processHTTPResponseHeader(response.allHeaderFields)
        case 400...499: try handleClientError(with: response)
        case 500...599: try handleServiceError(with: response)
        default: break
        }
    }
    
    open func processHTTPResponseHeader(_ header: [AnyHashable: Any]) throws {}
    
    open func handleClientError(with response: HTTPURLResponse) throws {
        throw GenericHTTPResponseError(response: response)
    }
    
    open func handleServiceError(with response: HTTPURLResponse) throws {
        throw GenericHTTPResponseError(response: response)
    }
    
    open func processData(with data: Data) throws {}
    
    open func willFinishProcess() throws {}
    
    private func errorOut(with error: Error) {
        success = false
        self.error = error
        finish()
    }
    
    override func onCancel() {
        dataRequest?.cancel()
    }
}

class GenericHTTPResponseError: NSError {
    let response: HTTPURLResponse
    init(response: HTTPURLResponse) {
        self.response = response
        super.init(domain: "api.domain", code: response.statusCode, userInfo: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
