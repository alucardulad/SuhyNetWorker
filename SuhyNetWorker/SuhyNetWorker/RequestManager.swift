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


/// 管理全局请求任务的单例入口。
///
/// 使用示例：
/// ```swift
/// RequestManager.default.request("https://api.example.com", params: ["a":1])
///     .cache(true)
///     .responseData { value in /* 处理回调 */ }
/// ```
class RequestManager {
    static let `default` = RequestManager()
    private var requestTasks = [String: RequestTaskManager]()
    private var timeoutIntervalForRequest: TimeInterval? /// 超时时间
    
    /// 设置请求超时时间（秒）。会影响后续新创建的 `RequestTaskManager` 实例。
    /// - Parameter timeInterval: 超时时间，单位为秒
    func timeoutIntervalForRequest(_ timeInterval :TimeInterval) {
        self.timeoutIntervalForRequest = timeInterval
        RequestManager.default.timeoutIntervalForRequest = timeoutIntervalForRequest
    }
    
    /// 创建或复用一个请求任务管理器并发起请求（回调式接口）。
    /// - Parameters:
    ///   - url: 请求 URL 字符串
    ///   - method: HTTP 方法，默认 `.get`
    ///   - params: 固定参数
    ///   - dynamicParams: 动态参数（会合并到 `params`）
    ///   - encoding: 参数编码方式，默认 `URLEncoding.default`
    ///   - headers: HTTP 头
    /// - Returns: `RequestTaskManager` 可用于链式调用（缓存/响应）
    func request(
        _ url: String,
        method: SuhyHTTPMethod = .get,
        params: Parameters? = nil,
        dynamicParams: Parameters? = nil,
        encoding: SuhyParameterEncoding = URLEncoding.default,
        headers: SuhyHTTPHeaders? = nil)
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
    
    /// 使用 `URLRequestConvertible` 发起请求并返回任务管理器（回调式接口）。
    /// - Parameters:
    ///   - urlRequest: 可转换为 `URLRequest` 的请求对象
    ///   - params: 与 URL 组合用于生成缓存 key 的参数
    ///   - dynamicParams: 额外动态参数
    /// - Returns: `RequestTaskManager?`，当无法从 `urlRequest` 取得 URL 时返回 nil
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
    
    
    /// 取消对应 URL + 参数 的正在进行中的请求。
    /// - Parameters:
    ///   - url: 请求 URL
    ///   - params: 参数（用于定位缓存 key）
    ///   - dynamicParams: 动态参数
    func cancel(_ url: String, params: Parameters? = nil, dynamicParams: Parameters? = nil) {
        let key = cacheKey(url, params, dynamicParams)
        let taskManager = requestTasks[key]
        taskManager?.dataRequest?.cancel()
    }
    
    /// 删除所有请求缓存。
    /// - Parameter completion: 删除完成后的回调，参数为是否成功
    func removeAllCache(completion: @escaping (Bool)->()) {
        CacheManager.default.removeAllCache(completion: completion)
    }
    
    /// 根据 URL 和参数计算的 key 清除单个缓存项。
    /// - Parameters:
    ///   - url: 请求 URL
    ///   - params: 参数（用于生成 key）
    ///   - dynamicParams: 动态参数
    ///   - completion: 完成回调
    func removeObjectCache(_ url: String, params: [String: Any]? = nil, dynamicParams: Parameters? = nil,  completion: @escaping (Bool)->()) {
        let key = cacheKey(url, params, dynamicParams)
        CacheManager.default.removeObjectCache(key, completion: completion)
    }
}

// MARK: - 请求任务
public class RequestTaskManager {
    /// 当前正在执行的 Alamofire 请求
    fileprivate var dataRequest: DataRequest?
    /// 是否启用本地缓存（写入/读取）
    fileprivate var cache: Bool = false
    /// 用于缓存的 key
    fileprivate var cacheKey: String!
    /// 可选的自定义 `Session`（用于设置超时等）
    fileprivate var Session: Session?
    /// 请求完成时的清理回调（用于从全局 map 中移除任务）
    fileprivate var completionClosure: (()->())?
    
    /// 给当前任务设置超时时间并返回自身以便链式调用。
    /// - Parameter timeInterval: 超时时间（秒）
    @discardableResult
    fileprivate func timeoutIntervalForRequest(_ timeInterval :TimeInterval) -> RequestTaskManager {
        self.Session = NetworkEngine.default.makeSession(timeout: timeInterval)
        return self
    }
    
    @discardableResult
    /// 发起请求并返回当前任务管理器，用于后续链式调用（例如设定缓存、响应处理）。
    fileprivate func request(
        _ url: String,
        method: SuhyHTTPMethod = .get,
        params: Parameters? = nil,
        cacheKey: String,
        encoding: SuhyParameterEncoding = URLEncoding.default,
        headers: SuhyHTTPHeaders? = nil)
        -> RequestTaskManager
    {
        self.cacheKey = cacheKey
        if Session != nil {
            dataRequest = Session?.request(url, method: method, parameters: params, encoding: encoding, headers: headers)
        } else {
            dataRequest = NetworkEngine.default.request(url, method: method, parameters: params, encoding: encoding, headers: headers)
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
    /// 使用 `URLRequestConvertible` 发起请求并返回任务管理器。
    /// - Parameters:
    ///   - urlRequest: 可转换成 `URLRequest` 的对象
    ///   - cacheKey: 用于缓存的 key
    fileprivate func request(
        urlRequest: URLRequestConvertible,
        cacheKey: String)
        -> RequestTaskManager {
            self.cacheKey = cacheKey
            if Session != nil {
                dataRequest = Session?.request(urlRequest)
            } else {
                dataRequest = NetworkEngine.default.request(urlRequest)
            }
        return self
    }
    
    /// 启用或禁用缓存写入/读取，返回自身以供链式调用。
    /// - Parameter cache: 是否缓存
    public func cache(_ cache: Bool) -> RequestTaskManager {
        self.cache = cache
        return self
    }
    /// 立即返回本请求对应的缓存数据（异步回调式）。
    /// - Parameter completion: 当缓存存在时返回 `Data`
    @discardableResult
    public func cacheData(completion: @escaping (Data)->()) -> SuhyDataResponse {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return dataResponse.cacheData(completion: completion)
    }
    /// 回调式响应 Data 结果。
    /// - Parameter completion: 返回 `SuhyValue<Data>`，其中包含是否来自缓存、结果和 HTTPURLResponse
    public func responseData(completion: @escaping (SuhyValue<Data>)->()) {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseData(completion: completion)
    }
    /// 先尝试返回缓存（若启用），然后异步返回网络数据（回调式）。
    /// - Parameter completion: 多次调用时会先返回 isCacheData = true 的值
    public func responseCacheAndData(completion: @escaping (SuhyValue<Data>)->()) {
        let dataResponse = SuhyDataResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        dataResponse.responseCacheAndData(completion: completion)
    }
    /// 立即返回本请求对应的缓存字符串（回调式）。
    /// - Parameter completion: 当缓存存在时返回 `String`
    @discardableResult
    public func cacheString(completion: @escaping (String)->()) -> SuhyStringResponse {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        return stringResponse.cacheString(completion:completion)
    }
    /// 回调式响应 String 结果。
    /// - Parameter completion: 返回 `SuhyValue<String>`，其中包含是否来自缓存、结果和 HTTPURLResponse
    public func responseString(completion: @escaping (SuhyValue<String>)->()) {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseString(completion: completion)
    }
    /// 先尝试返回缓存字符串（若启用），然后异步返回网络字符串（回调式）。
    /// - Parameter completion: 多次调用时会先返回 isCacheData = true 的值
    public func responseCacheAndString(completion: @escaping (SuhyValue<String>)->()) {
        let stringResponse = SuhyStringResponse(dataRequest: dataRequest!, cache: cache, cacheKey: cacheKey, completionClosure: completionClosure)
        stringResponse.responseCacheAndString(completion: completion)
    }
    // MARK: - Async / Await APIs
    /// 使用 Swift async/await 获取 Data 响应。
    ///
    /// 如果本任务启用了缓存且存在缓存数据，会立即返回 `isCacheData = true` 的 `SuhyValue`。
    /// 否则会等待网络请求完成并返回网络结果。
    /// - Returns: `SuhyValue<Data>`，包含结果与是否来自缓存标记
    public func responseData() async -> SuhyValue<Data> {
        if cache {
            if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data {
                return SuhyValue(isCacheData: true, result: Alamofire.AFResult.success(data), response: nil)
            }
        }
        guard let req = dataRequest else {
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.failure(AFError.explicitlyCancelled), response: nil)
        }
        do {
            let data = try await req.serializingData().value
            if openResultLog {
                if let str = String(data: data, encoding: .utf8) {
                    SuhyLog(str)
                }
            }
            if cache {
                var model = CacheModel()
                model.data = data
                CacheManager.default.setObject(model, forKey: cacheKey)
            }
            if completionClosure != nil { completionClosure!() }
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.success(data), response: req.response)
        } catch {
            if openResultLog {
                SuhyLog(error.localizedDescription)
            }
            if completionClosure != nil { completionClosure!() }
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.failure(error), response: req.response)
        }
    }

    /// 使用 Swift async/await 获取 String 响应。
    ///
    /// 行为与 `responseData()` 类似，支持优先返回缓存文本（若启用并存在），否则等待网络结果。
    /// - Returns: `SuhyValue<String>`，包含结果与是否来自缓存标记
    public func responseString() async -> SuhyValue<String> {
        if cache {
            if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data,
                let str = String(data: data, encoding: .utf8) {
                return SuhyValue(isCacheData: true, result: Alamofire.AFResult.success(str), response: nil)
            }
        }
        guard let req = dataRequest else {
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.failure(AFError.explicitlyCancelled), response: nil)
        }
        do {
            let str = try await req.serializingString().value
            if openResultLog {
                SuhyLog(str)
            }
            if cache {
                var model = CacheModel()
                model.data = str.data(using: .utf8)
                CacheManager.default.setObject(model, forKey: cacheKey)
            }
            if completionClosure != nil { completionClosure!() }
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.success(str), response: req.response)
        } catch {
            if openResultLog {
                SuhyLog(error.localizedDescription)
            }
            if completionClosure != nil { completionClosure!() }
            return SuhyValue(isCacheData: false, result: Alamofire.AFResult.failure(error), response: req.response)
        }
    }

    /// 仅读取本地缓存的 Data（异步友好同步读取）。
    /// - Returns: 若存在则返回 Data，否则返回 nil
    public func cacheDataAsync() async -> Data? {
        return CacheManager.default.objectSync(forKey: cacheKey)?.data
    }

    /// 仅读取本地缓存的 String（异步友好同步读取）。
    /// - Returns: 若存在则返回 String，否则返回 nil
    public func cacheStringAsync() async -> String? {
        if let data = CacheManager.default.objectSync(forKey: cacheKey)?.data {
            return String(data: data, encoding: .utf8)
        }
        return nil
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
