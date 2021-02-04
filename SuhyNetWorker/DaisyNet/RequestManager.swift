//
//  RequestManager.swift
//  SuhyNetWorker
//
//  Created by Alucardulad on 2020/10/12.
//  Copyright © 2020年 Alucardulad. All rights reserved.
//
//  https://github.com/Alucardulad/SuhyNetWorker
//
import Foundation
import Alamofire

class RequestManager {
    static let `default` = RequestManager()
    private var requestTasks = [String: RequestTaskManager]()
    private var timeoutIntervalForRequest: TimeInterval? /// 超时时间
    
    func timeoutIntervalForRequest(_ timeInterval :TimeInterval) {
        self.timeoutIntervalForRequest = timeInterval
        RequestManager.default.timeoutIntervalForRequest = timeoutIntervalForRequest
    }
    
    func request(
        _ url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        dynamicParams: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> RequestTaskManager
    {
        let key = cacheKey(url, params, dynamicParams)
        var taskManager : RequestTaskManager?
        if requestTasks[key] == nil {
            if timeoutIntervalForRequest != nil {
                taskManager = RequestTaskManager().timeoutIntervalForRequest(timeoutIntervalForRequest!)
            } else {
                taskManager = RequestTaskManager()
            }
            requestTasks[key] = taskManager
        } else {
            taskManager = requestTasks[key]
        }
        
        taskManager?.completionClosure = {
            self.requestTasks.removeValue(forKey: key)
        }
        var tempParam = params==nil ? [:] : params!
        let dynamicTempParam = dynamicParams==nil ? [:] : dynamicParams!
        dynamicTempParam.forEach { (arg) in
            tempParam[arg.key] = arg.value
        }
        taskManager?.request(url, method: method, params: tempParam, cacheKey: key, encoding: encoding, headers: headers)
        return taskManager!
    }
    
    func request(
        urlRequest: URLRequestConvertible,
        params: Parameters,
        dynamicParams: Parameters? = nil)
        -> RequestTaskManager? {
            if let urlStr = urlRequest.urlRequest?.url?.absoluteString {
                let components = urlStr.components(separatedBy: "?")
                if components.count > 0 {
                    let key = cacheKey(components.first!, params, dynamicParams)
                    var taskManager : RequestTaskManager?
                    if requestTasks[key] == nil {
                        if timeoutIntervalForRequest != nil {
                            taskManager = RequestTaskManager().timeoutIntervalForRequest(timeoutIntervalForRequest!)
                        } else {
                            taskManager = RequestTaskManager()
                        }
                        requestTasks[key] = taskManager
                    } else {
                        taskManager = requestTasks[key]
                    }
                    
                    taskManager?.completionClosure = {
                        self.requestTasks.removeValue(forKey: key)
                    }
                    var tempParam = params
                    let dynamicTempParam = dynamicParams==nil ? [:] : dynamicParams!
                    dynamicTempParam.forEach { (arg) in
                        tempParam[arg.key] = arg.value
                    }
                    taskManager?.request(urlRequest: urlRequest, cacheKey: key)
                    return taskManager!
                }
                return nil
            }
            return nil
    }
    
    
    /// 取消请求
    func cancel(_ url: String, params: Parameters? = nil, dynamicParams: Parameters? = nil) {
        let key = cacheKey(url, params, dynamicParams)
        let taskManager = requestTasks[key]
        taskManager?.dataRequest?.cancel()
    }
    
    /// 清除所有缓存
    func removeAllCache(completion: @escaping (Bool)->()) {
        CacheManager.default.removeAllCache(completion: completion)
    }
    
    /// 根据key值清除缓存
    func removeObjectCache(_ url: String, params: [String: Any]? = nil, dynamicParams: Parameters? = nil,  completion: @escaping (Bool)->()) {
        let key = cacheKey(url, params, dynamicParams)
        CacheManager.default.removeObjectCache(key, completion: completion)
    }
}

// MARK: - 请求任务
public class RequestTaskManager {
    fileprivate var dataRequest: DataRequest?
    fileprivate var cache: Bool = false
    fileprivate var cacheKey: String!
    fileprivate var Session: Session?
    fileprivate var completionClosure: (()->())?
    
    @discardableResult
    fileprivate func timeoutIntervalForRequest(_ timeInterval :TimeInterval) -> RequestTaskManager {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeInterval
        let Session = Alamofire.Session(configuration: configuration)
        self.Session = Session
        return self
    }
    
    @discardableResult
    fileprivate func request(
        _ url: String,
        method: HTTPMethod = .get,
        params: Parameters? = nil,
        cacheKey: String,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> RequestTaskManager
    {
        self.cacheKey = cacheKey
        if Session != nil {
            dataRequest = Session?.request(url, method: method, parameters: params, encoding: encoding, headers: headers)
        } else {
            dataRequest = AF.request(url, method: method, parameters: params, encoding: encoding, headers: headers)
        }
        
        return self
    }
    
    
    /// request
    ///
    /// - Parameters:
    ///   - urlRequest: urlRequest
    ///   - cacheKey: cacheKey
    /// - Returns: RequestTaskManager
    @discardableResult
    fileprivate func request(
        urlRequest: URLRequestConvertible,
        cacheKey: String)
        -> RequestTaskManager {
            self.cacheKey = cacheKey
            if Session != nil {
                dataRequest = Session?.request(urlRequest)
            } else {
                dataRequest = AF.request(urlRequest)
            }
        return self
    }
    
    /// 是否缓存数据
    public func cache(_ cache: Bool) -> RequestTaskManager {
        self.cache = cache
        return self
    }
    /// 获取缓存Data
    @discardableResult
    public func cacheData(completion: @escaping (Data)->()) -> SuhyDataResponse {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return dataResponse.cacheData(completion: completion)
    }
    /// 响应Data
    public func responseData(completion: @escaping (SuhyValue<Data>)->()) {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseData(completion: completion)
    }
    /// 先获取Data缓存，再响应Data
    public func responseCacheAndData(completion: @escaping (SuhyValue<Data>)->()) {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseCacheAndData(completion: completion)
    }
    /// 获取缓存String
    @discardableResult
    public func cacheString(completion: @escaping (String)->()) -> SuhyStringResponse {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return stringResponse.cacheString(completion:completion)
    }
    /// 响应String
    public func responseString(completion: @escaping (SuhyValue<String>)->()) {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseString(completion: completion)
    }
    /// 先获取缓存String,再响应String
    public func responseCacheAndString(completion: @escaping (SuhyValue<String>)->()) {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseCacheAndString(completion: completion)
    }
    /// 获取缓存JSON
    @discardableResult
    public func cacheJson(completion: @escaping (Any)->()) -> SuhyJsonResponse {
        let jsonResponse = SuhyJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return jsonResponse.cacheJson(completion:completion)
    }
    /// 响应JSON
    public func responseJson(completion: @escaping (SuhyValue<Any>)->()) {
        let jsonResponse = SuhyJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        jsonResponse.responseJson(completion: completion)
    }
    /// 先获取缓存JSON，再响应JSON
    public func responseCacheAndJson(completion: @escaping (SuhyValue<Any>)->()) {
        let jsonResponse = SuhyJsonResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        jsonResponse.responseCacheAndJson(completion: completion)
    }
}
// MARK: - SuhyBaseResponse
public class SuhyResponse {
    fileprivate var dataRequest: DataRequest
    fileprivate var cache: Bool
    fileprivate var cacheKey: String
    fileprivate var completionClosure: (()->())?
    fileprivate init(dataRequest: DataRequest, cache: Bool, cacheKey: String, completionClosure: (()->())?) {
        self.dataRequest = dataRequest
        self.cache = cache
        self.cacheKey = cacheKey
        self.completionClosure = completionClosure
    }
    ///
    fileprivate func response<T>(response: AFDataResponse<T>, completion: @escaping (SuhyValue<T>)->()) {
        responseCache(response: response) { (result) in
            completion(result)
        }
    }
    /// isCacheData
    fileprivate func responseCache<T>(response: AFDataResponse<T>, completion: @escaping (SuhyValue<T>)->()) {
        if completionClosure != nil { completionClosure!() }
        let result = SuhyValue(isCacheData: false, result: response.result, response: response.response)
        if openResultLog {
            SuhyLog("================请求数据=====================")
        }
        if openUrlLog {
            SuhyLog(response.request?.url?.absoluteString ?? "")
        }
        switch response.result {
        case .success(_):
            if openResultLog {
                if let data = response.data,
                    let str = String(data: data, encoding: .utf8) {
                    SuhyLog(str)
                }
            }
            if self.cache {/// 写入缓存
                var model = CacheModel()
                model.data = response.data
                CacheManager.default.setObject(model, forKey: self.cacheKey)
            }
        case .failure(let error):
            if openResultLog {
                SuhyLog(error.localizedDescription)
            }
        }
        completion(result)
    }
}
// MARK: - SuhyJsonResponse
public class SuhyJsonResponse: SuhyResponse {
    /// 响应JSON
    func responseJson(completion: @escaping (SuhyValue<Any>)->()) {
        dataRequest.responseJSON(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    fileprivate func responseCacheAndJson(completion: @escaping (SuhyValue<Any>)->()) {
        if cache { cacheJson(completion: { (json) in
            let res = SuhyValue(isCacheData: true, result: Alamofire.AFResult.success(json), response: nil)
            completion(res)
        }) }
        dataRequest.responseJSON { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
    /// 获取缓存json
    @discardableResult
    fileprivate func cacheJson(completion: @escaping (Any)->()) -> SuhyJsonResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data,
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            if openResultLog {
                SuhyLog("=================缓存=====================")
                if let str = String(data: data, encoding: .utf8) {
                    SuhyLog(str)
                }
            }
            completion(json)
        } else {
            if openResultLog {
                SuhyLog("读取缓存失败")
            }
        }
        return self
    }
}
// MARK: - SuhyStringResponse
public class SuhyStringResponse: SuhyResponse {
    /// 响应String
    func responseString(completion: @escaping (SuhyValue<String>)->()) {
        dataRequest.responseString(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    @discardableResult
    fileprivate func cacheString(completion: @escaping (String)->()) -> SuhyStringResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data,
            let str = String(data: data, encoding: .utf8) {
            completion(str)
        } else {
            if openResultLog {
                SuhyLog("读取缓存失败")
            }
        }
        return self
    }
    fileprivate func responseCacheAndString(completion: @escaping (SuhyValue<String>)->()) {
        if cache { cacheString(completion: { str in
            let res = SuhyValue(isCacheData: true, result: Alamofire.AFResult.success(str), response: nil)
            completion(res)
        })}
        dataRequest.responseString { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
}
// MARK: - SuhyDataResponse
public class SuhyDataResponse: SuhyResponse {
    /// 响应Data
    func responseData(completion: @escaping (SuhyValue<Data>)->()) {
        dataRequest.responseData(completionHandler: { response in
            self.response(response: response, completion: completion)
        })
    }
    @discardableResult
    fileprivate func cacheData(completion: @escaping (Data)->()) -> SuhyDataResponse {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data {
            completion(data)
        } else {
            if openResultLog {
                SuhyLog("读取缓存失败")
            }
        }
        return self
    }
    fileprivate func responseCacheAndData(completion: @escaping (SuhyValue<Data>)->()) {
        if cache { cacheData(completion: { (data) in
            let res = SuhyValue(isCacheData: true, result: Alamofire.AFResult.success(data), response: nil)
            completion(res)
        }) }
        dataRequest.responseData { (response) in
            self.responseCache(response: response, completion: completion)
        }
    }
}
