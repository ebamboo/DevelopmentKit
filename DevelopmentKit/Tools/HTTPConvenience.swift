//
//  Created by ebamboo on 2023/12/15.
//
//  根据具体的项目约定，解析返回数据
//

import Alamofire
import HandyJSON

// MARK: - core

struct Payload {
    
    var errorCode: Int
    var message: String?
    var data: Any?
    
}

extension HTTP {
    
    /// 只试图解析响应体，并不解析实际的业务数据
    @discardableResult
    static func request(_ request: HTTPRequest,
                        requestModifier: RequestModifier? = nil,
                        completionHandler: @escaping (_ result: Result<(HTTPResponse, Payload), HTTPError>) -> Void
    ) -> DataTask {
        let task = dataRequest(request, requestModifier: requestModifier) { result in
            switch result {
            case .success(let response):
                //-------在这里根据实际项目需求统一处理一下 HTTP statusCode
                // ...
                //---------------------------------------------------
                guard let jsonData = response.body, !jsonData.isEmpty,
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let errorCode = jsonObject["errorCode"] as? Int else {
                    completionHandler(.failure(.decodeError(message: "服务器返回数据格式错误")))
                    return
                }
                //-------在这里根据实际项目需求统一处理一下 errorCode
                // ...
                //---------------------------------------------------
                let payload = Payload(errorCode: errorCode, message: jsonObject["message"] as? String, data: jsonObject["data"])
                completionHandler(.success((response, payload)))
            case .failure(let error):
                completionHandler(.failure(.alamofire(error: error)))
            }
        }
        return task
    }
    
    /// 直接把业务数据转为指定类数据类型，并返回该数据。
    /// 只接受这些数据类型：[M]、M、布尔、整形、浮点型、字符串、数组、字典。
    /// 其中 M 遵循 HandyJSON 协议
    /// 数组和字典的元素只允许这些类型：布尔、整形、浮点型、字符串、数组、字典
    /// 其他类型行为未定义。
    @discardableResult
    static func request<Data>(_ request: HTTPRequest,
                              requestModifier: RequestModifier? = nil,
                              decodeDataOnly dataType: Data.Type,
                              completionHandler: @escaping (_ result: Result<Data, HTTPError>) -> Void
    ) -> DataTask {
        let task = dataRequest(request, requestModifier: requestModifier) { result in
            switch result {
            case .success(let response):
                //-------在这里根据实际项目需求统一处理一下 HTTP statusCode
                // ...
                //---------------------------------------------------
                guard let jsonData = response.body, !jsonData.isEmpty,
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let _ = jsonObject["errorCode"] as? Int else {
                    completionHandler(.failure(.decodeError(message: "服务器返回数据格式错误")))
                    return
                }
                //-------在这里根据实际项目需求统一处理一下 errorCode
                // ...
                //---------------------------------------------------
                let result: Result<Data, HTTPError> = {
                    guard let data = jsonObject["data"] else {
                        return .failure(.decodeError(message: "data数据为空"))
                    }
                    if let decodableArrayType = Data.self as? any DecodableArray.Type {
                        guard let list = decodableArrayType.deserialize(from: data as? [Any]) else {
                            return .failure(.decodeError(message: "data数据无法解析为模型数组"))
                        }
                        return .success(list.compactMap({ $0 }) as! Data)
                    }
                    if let decodableModelType = Data.self as? HandyJSON.Type {
                        guard let model = decodableModelType.deserialize(from: data as? [String: Any]) else {
                            return .failure(.decodeError(message: "data数据无法解析为模型"))
                        }
                        return .success(model as! Data)
                    }
                    if let data = data as? Data {
                        return .success(data)
                    }
                    return .failure(.decodeError(message: "data数据无法解析为\(Data.self)"))
                }()
                completionHandler(result)
            case .failure(let error):
                completionHandler(.failure(.alamofire(error: error)))
            }
        }
        return task
    }
    
}

// MARK: - support

enum HTTPError: Error {
    case decodeError(message: String)
    case alamofire(error: AFError)
    var message: String {
        switch self {
        case .decodeError(let message):
            return message
        case .alamofire(let error):
            return error.errorDescription ?? "alamofire未返回错误说明"
        }
    }
}

protocol DecodableArray {
    associatedtype DecodableElement
    static func deserialize(from array: [Any]?) -> [DecodableElement?]?
}

extension Array: DecodableArray where Element: HandyJSON {
    typealias DecodableElement = Element
}
