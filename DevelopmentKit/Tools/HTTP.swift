//
//  Created by ebamboo on 2021/11/19.
//

import Alamofire

// MARK: - core

protocol HTTPRequest {
    
    var method: HTTP.Method { get }
    
    var url: String { get }
    
    var headers: [String: String] { get }
    
    var body: HTTP.Body { get }
    
}

struct HTTPResponse {
    
    var statusCode: Int
    
    var headers: [String: Any]
    
    var body: Data?
    
}

extension HTTP {
    
    /// 通用数据数据请求
    @discardableResult
    static func dataRequest(_ request: HTTPRequest,
                            requestModifier: RequestModifier? = nil,
                            completionHandler: @escaping (_ result: Result<HTTPResponse, AFError>) -> Void
    ) -> DataTask {
        #if DEBUG
        printRequest(request)
        #endif
        let body: (params: Parameters?, encoding: ParameterEncoding) = {
            switch request.body {
            case .none, .multipart:
                return (nil, URLEncoding.default)
            case .plain(text: let text):
                return (nil, PlainParameterEncoding(text: text))
            case .json(params: let params):
                return (params, JSONEncoding.default)
            case .query(params: let params):
                return (params, URLEncoding.httpBody)
            }
        }()
        let task = AF.request(request.url,
                              method: request.method,
                              parameters: body.params,
                              encoding: body.encoding,
                              headers: HTTPHeaders(request.headers),
                              requestModifier: requestModifier)
        task.response { dataResponse in
            #if DEBUG
            printResponse(dataResponse.response, request: request, result: dataResponse.result)
            #endif
            let result: Result<HTTPResponse, AFError> = {
                switch dataResponse.result {
                case .success(let data):
                    let response = HTTPResponse(statusCode: dataResponse.response?.statusCode ?? statusCodeMissing,
                                                headers: dataResponse.response?.allHeaderFields as? [String: Any] ?? [:],
                                                body: data)
                    return .success(response)
                case .failure(let error):
                    return .failure(error)
                }
            }()
            completionHandler(result)
        }
        return task
    }
    
    /// 文件上传
    @discardableResult
    static func uploadRequest(_ request: HTTPRequest,
                              requestModifier: RequestModifier? = nil,
                              progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                              completionHandler: @escaping (_ result: Result<HTTPResponse, AFError>) -> Void
    ) -> UploadTask {
        #if DEBUG
        printRequest(request)
        #endif
        let task = AF.upload(multipartFormData: { formData in
            switch request.body {
            case .multipart(let params, let files):
                for (key, value) in params {
                    formData.append(value.data(using: .utf8)!, withName: key)
                }
                files.forEach { file in
                    switch file {
                    case .fileData(let data, name: let name, fileName: let fileName, mimeType: let mimeType):
                        formData.append(data, withName: name, fileName: fileName, mimeType: mimeType)
                    case .fileURL(let url, name: let name, fileName: let fileName, mimeType: let mimeType):
                        formData.append(url, withName: name, fileName: fileName, mimeType: mimeType)
                    }
                }
            default:
                break
            }
        }, to: request.url, method: request.method, headers: HTTPHeaders(request.headers), requestModifier: requestModifier)
        task.uploadProgress(closure: progressHandler)
        task.response { uploadResponse in
            #if DEBUG
            printResponse(uploadResponse.response, request: request, result: uploadResponse.result)
            #endif
            let result: Result<HTTPResponse, AFError> = {
                switch uploadResponse.result {
                case .success(let data):
                    let response = HTTPResponse(statusCode: uploadResponse.response?.statusCode ?? statusCodeMissing,
                                                headers: uploadResponse.response?.allHeaderFields as? [String: Any] ?? [:],
                                                body: data)
                    return .success(response)
                case .failure(let error):
                    return .failure(error)
                }
            }()
            completionHandler(result)
        }
        return task
    }
    
    /// 文件下载 1
    /// body 为本地储存路径
    @discardableResult
    static func downloadRequest(_ request: HTTPRequest,
                                to destination: DownloadDestination? = nil,
                                requestModifier: RequestModifier? = nil,
                                progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                                completionHandler: @escaping (_ result: Result<HTTPResponse, AFError>) -> Void
    ) -> DownloadTask {
        #if DEBUG
        printRequest(request)
        #endif
        let task = AF.download(request.url, headers: HTTPHeaders(request.headers), requestModifier: requestModifier) { temporaryURL, response in
            if let destination = destination {
                let fileName = temporaryURL.lastPathComponent
                return (destination(fileName), [.createIntermediateDirectories, .removePreviousFile])
            } else {
                let fileName = "Alamofire_\(temporaryURL.lastPathComponent)"
                let fileURL = temporaryURL.deletingLastPathComponent().appendingPathComponent(fileName)
                return (fileURL, [])
            }
        }
        task.downloadProgress(closure: progressHandler)
        task.response { downloadResponse in
            #if DEBUG
            printResponse(downloadResponse.response, request: request, result: {
                switch downloadResponse.result {
                case .success(let url):
                    return .success(url?.absoluteString.data(using: .utf8))
                case .failure(let error):
                    return .failure(error)
                }
            }())
            #endif
            let result: Result<HTTPResponse, AFError> = {
                switch downloadResponse.result {
                case .success(let url):
                    let response = HTTPResponse(statusCode: downloadResponse.response?.statusCode ?? statusCodeMissing,
                                                headers: downloadResponse.response?.allHeaderFields as? [String: Any] ?? [:],
                                                body: url?.absoluteString.data(using: .utf8))
                    return .success(response)
                case .failure(let error):
                    return .failure(error)
                }
            }()
            completionHandler(result)
        }
        return task
    }
    
    /// 文件下载 2
    /// body 为本地储存路径
    @discardableResult
    static func downloadRequest(with resumeData: Data,
                                to destination: DownloadDestination? = nil,
                                progressHandler: @escaping (_ progress: Progress) -> Void = { _ in },
                                completionHandler: @escaping (_ result: Result<HTTPResponse, AFError>) -> Void
    ) -> DownloadTask {
        let task = AF.download(resumingWith: resumeData) { temporaryURL, response in
            if let destination = destination {
                let fileName = temporaryURL.lastPathComponent
                return (destination(fileName), [.createIntermediateDirectories, .removePreviousFile])
            } else {
                let fileName = "Alamofire_\(temporaryURL.lastPathComponent)"
                let fileURL = temporaryURL.deletingLastPathComponent().appendingPathComponent(fileName)
                return (fileURL, [])
            }
        }
        task.downloadProgress(closure: progressHandler)
        task.response { downloadResponse in
            let result: Result<HTTPResponse, AFError> = {
                switch downloadResponse.result {
                case .success(let url):
                    let response = HTTPResponse(statusCode: downloadResponse.response!.statusCode,
                                                headers: downloadResponse.response?.allHeaderFields as? [String: Any] ?? [:],
                                                body: url?.absoluteString.data(using: .utf8))
                    return .success(response)
                case .failure(let error):
                    return .failure(error)
                }
            }()
            completionHandler(result)
        }
        return task
    }
    
}

// MARK: - support

struct HTTP {
    
    typealias Method = Alamofire.HTTPMethod
    
    enum Body {
        case none
        case plain(text: String)
        case json(params: [String: Any])
        case query(params: [String: String])
        case multipart(params: [String: String], files: [UploadFileModel])
    }
    
    enum UploadFileModel {
        case fileData(_ data: Data, name: String, fileName: String? = nil, mimeType: String? = nil)
        case fileURL(_ url: URL, name: String, fileName: String, mimeType: String)
    }
    
    typealias DownloadDestination = (_ fileName: String) -> URL
    
    struct PlainParameterEncoding: Alamofire.ParameterEncoding {
        let text: String
        func encode(_ urlRequest: any URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            var request = try urlRequest.asURLRequest()
            request.httpBody = text.data(using: .utf8)
            return request
        }
    }
    
    typealias RequestModifier = Alamofire.Session.RequestModifier
    
    typealias DataTask = Alamofire.DataRequest
    typealias UploadTask = Alamofire.UploadRequest
    typealias DownloadTask = Alamofire.DownloadRequest
    
    static let statusCodeMissing = -1 // HTTP 响应状态吗缺失时的默认值，一般不会出现这种情况，需开发时解决该问题
    
}

// MARK: - debug

extension HTTP {
    
    /// 打印 HTTP 请求报文
    static func printRequest(_ request: HTTPRequest) {
        print("request line = \(request.method) \(request.url)")
        let headersData = try! JSONSerialization.data(withJSONObject: request.headers, options: .prettyPrinted)
        let headersString = String(data: headersData, encoding: .utf8)!
        print("request headers = \(headersString)")
        let bodyString = {
            switch request.body {
            case .none:
                return "null"
            case .plain(text: let text):
                return text
            case .json(params: let params):
                let paramsData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                let paramsString = String(data: paramsData, encoding: .utf8)!
                return paramsString
            case .query(params: let params):
                let paramsString = params.keys.map { key in
                    "\(key)=\(params[key]!)"
                }.joined(separator: "&")
                return paramsString
            case .multipart(params: let params, files: let files):
                var formDataList = params
                files.forEach { file in
                    switch file {
                    case .fileData(_, let name, _, _):
                        formDataList[name] = "Data方式上传的二进制数据"
                    case .fileURL(_, let name, _, _):
                        formDataList[name] = "URL方式上传的二进制数据"
                    }
                }
                let paramsData = try! JSONSerialization.data(withJSONObject: formDataList, options: .prettyPrinted)
                let paramsString = String(data: paramsData, encoding: .utf8)!
                return paramsString
            }
        }()
        print("request body = \(bodyString)")
    }
    
    /// 打印 HTTP 响应报文
    static func printResponse(_ response: HTTPURLResponse?, request: HTTPRequest, result: Result<Data?, AFError>) {
        switch result {
        case .success(let data):
            print("response line = \(response?.statusCode ?? statusCodeMissing) \(request.url)")
            let headersData = try! JSONSerialization.data(withJSONObject: response?.allHeaderFields as? [String: Any] ?? [:], options: .prettyPrinted)
            let headersString = String(data: headersData, encoding: .utf8)!
            print("response headers = \(headersString)")
            let bodyString = {
                guard let data = data, !data.isEmpty else { return "null" }
                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                    let jsonData = try! JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    return jsonString
                } else if let text = String(data: data, encoding: .utf8) {
                    return text
                } else {
                    return "body数据存在但无法转为字符串或JSON"
                }
            }()
            print("response body = \(bodyString)")
        case .failure(let error):
            print("request failed !!! \(request.url)")
            print("request failed error !!! \(error.errorDescription ?? "alamofire未返回说明")")
        }
    }
    
}
