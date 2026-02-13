//
//  DownloadManager.swift
//  SuhyNetWorker
//
//  Created by Alucardulad on 2020/10/12.
//  Copyright © 2020年 Alucardulad. All rights reserved.
//
//  https://github.com/Alucardulad/SuhyNetWorker
//
import Foundation
import Alamofire

/// 下载相关错误定义
public enum DownloadError: Error {
    case noRequest
}

// MARK: - downloadManager
/// 下载管理器（单例）
///
/// 负责创建和管理 `DownloadTaskManager` 实例。保留原有基于 closure 的 API，同时提供 async/await 便捷入口。
/// 使用示例：
/// ```swift
/// // closure 风格
/// DownloadManager.default.download(url).response { result in }
/// // async/await 风格
/// let fileUrl = try await DownloadManager.default.downloadAsync(url)
/// ```
class DownloadManager {
    static let `default` = DownloadManager()
    /// 下载任务管理
    fileprivate var downloadTasks = [String: DownloadTaskManager]()
    
    func download(
        _ url: String,
        method: SuhyHTTPMethod = .get,
        parameters: Parameters? = nil,
        dynamicParams: Parameters? = nil,
        encoding: SuhyParameterEncoding = URLEncoding.default,
        headers: SuhyHTTPHeaders? = nil,
        fileName: String? = nil)
        ->DownloadTaskManager
    {
        let key = cacheKey(url, parameters, dynamicParams)
        let taskManager = DownloadTaskManager(url, parameters: parameters, dynamicParams: dynamicParams)
        var tempParam = parameters==nil ? [:] : parameters!
        let dynamicTempParam = dynamicParams==nil ? [:] : dynamicParams!
        dynamicTempParam.forEach { (arg) in
            tempParam[arg.key] = arg.value
        }
        taskManager.download(url, method: method, parameters: tempParam, encoding: encoding, headers: headers, fileName: fileName)
        self.downloadTasks[key] = taskManager
        taskManager.cancelCompletion = {
            self.downloadTasks.removeValue(forKey: key)
        }
        return taskManager
    }

    /// 简单的 async/await 下载入口，可直接等待下载完成并返回文件 URL 字符串。
    /// - Note: 该方法会调用原有的 `download(...)` 来创建任务，并等待 `DownloadTaskManager.response()`。
    public func downloadAsync(
        _ url: String,
        method: SuhyHTTPMethod = .get,
        parameters: Parameters? = nil,
        dynamicParams: Parameters? = nil,
        encoding: SuhyParameterEncoding = URLEncoding.default,
        headers: SuhyHTTPHeaders? = nil,
        fileName: String? = nil) async throws -> String? {

        let task = download(url, method: method, parameters: parameters, dynamicParams: dynamicParams, encoding: encoding, headers: headers, fileName: fileName)
        return try await task.response()
    }
    /// 取消（暂停）指定 URL + 参数 的下载任务。
    /// - Note: 会发送 `SuhyDownloadCancel` 通知以通知任务停止。
    /// - Parameters:
    ///   - url: 下载 URL
    ///   - parameters: 参数
    ///   - dynamicParams: 动态参数
    func cancel(_ url: String, parameters: Parameters?, dynamicParams: Parameters? = nil) {
        let key = cacheKey(url, parameters, dynamicParams)
        let task = downloadTasks[key]
        task?.downloadRequest?.cancel()
        NotificationCenter.default.post(name: NSNotification.Name("SuhyDownloadCancel"), object: nil)
    }

    /// 取消所有正在进行的下载任务。
    func cancelAll() {
        for (key, task) in downloadTasks {
            task.downloadRequest?.cancel()
            task.cancelCompletion = {
                self.downloadTasks.removeValue(forKey: key)
            }
        }
    }

    /// 删除单个下载及其缓存文件。
    ///
    /// - If the download is running, it will be canceled and its resumeData + file path removed.
    /// - Parameters:
    ///   - url: 下载 URL
    ///   - parameters: 参数（用于生成缓存 key）
    ///   - dynamicParams: 动态参数
    ///   - completion: 删除完成回调，返回是否成功
    func delete(_ url: String, parameters: Parameters? , dynamicParams: Parameters? = nil, completion: @escaping (Bool)->()) {
        let key = cacheKey(url, parameters, dynamicParams)
        if let task = downloadTasks[key] {
            task.downloadRequest?.cancel()
            task.cancelCompletion = {
                self.downloadTasks.removeValue(forKey: key)
                CacheManager.default.removeObjectCache(key, completion: completion)
            }
        } else {
            if let path = getFilePath(key)
            { /// 下载完成了
                do {
                    let arr = path.components(separatedBy: "/")
                    let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    let fileURL = cachesURL.appendingPathComponent(arr.last!)
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    SuhyLog(error)
                }
            }
            CacheManager.default.removeObjectCache(key, completion: completion)
        }
    }
    /// 获取已下载文件的本地路径（若存在）。
    /// - Returns: 文件 `URL` 或 nil
    func downloadFilePath(_ url: String, parameters: Parameters?, dynamicParams: Parameters? = nil) -> URL? {
        let key = cacheKey(url, parameters, dynamicParams)
        if let path = getFilePath(key),
            let pathUrl = URL(string: path) {
            return pathUrl
        }
        return nil
    }
    /// 获取下载进度（0.0 - 1.0）。
    /// - Returns: 进度的双精度值
    func downloadPercent(_ url: String, parameters: Parameters?, dynamicParams: Parameters? = nil) -> Double {
        let key = cacheKey(url, parameters, dynamicParams)
        let percent = getProgress(key)
        return percent
    }
    /// 查询下载状态（downloading / suspend / complete）。
    func downloadStatus(_ url: String, parameters: Parameters?, dynamicParams: Parameters? = nil) -> DownloadStatus {
        let key = cacheKey(url, parameters, dynamicParams)
        let task = downloadTasks[key]
        if downloadPercent(url, parameters: parameters) == 1 { return .complete }
        return task?.downloadStatus ?? .suspend
    }
    /// 订阅下载进度（回调式）。
    /// - Returns: 如果任务正在下载返回该 `DownloadTaskManager`，否则返回 nil 并立即通过 `progress` 回传当前进度
    @discardableResult
    func downloadProgress(_ url: String, parameters: Parameters?, dynamicParams: Parameters? = nil, progress: @escaping ((Double)->())) -> DownloadTaskManager? {
        let key = cacheKey(url, parameters, dynamicParams)
        if let task = downloadTasks[key], downloadPercent(url, parameters: parameters) < 1 {
            task.downloadProgress(progress: { pro in
                progress(pro)
            })
            return task
        } else {
            let pro = downloadPercent(url, parameters: parameters)
            progress(pro)
            return nil
        }
    }
}

// MARK: - 下载状态
/// 下载状态枚举
public enum DownloadStatus {
    case downloading
    case suspend
    case complete
}

// MARK: - taskManager
public class DownloadTaskManager {
    /// 当前 Alamofire 下载请求
    fileprivate var downloadRequest: DownloadRequest?
    /// 当前任务的状态
    fileprivate var downloadStatus: DownloadStatus = .suspend
    /// 取消时的回调（用于从管理器中移除任务）
    fileprivate var cancelCompletion: (()->())?
    fileprivate var cccompletion: (()->())?
    /// 保存进度/resumeData/filePath 等缓存数据的字典
    var cacheDictionary = [String: Data]()
    /// 用于缓存的 key
    private var key: String
    
        /// 初始化并生成缓存 key，同时监听应用退到后台或取消通知以处理下载状态。
        /// - Parameters:
        ///   - url: 下载 URL（用于生成缓存 key）
        ///   - parameters: 参数
        ///   - dynamicParams: 动态参数（例如时间戳 / token）
        init(_ url: String,
            parameters: Parameters? = nil,
            dynamicParams: Parameters? = nil) {
        key = cacheKey(url, parameters, dynamicParams)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadCancel), name: NSNotification.Name.init("SuhyDownloadCancel"), object: nil)
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (_) in
            self.downloadRequest?.cancel()
        }
    }
    @objc fileprivate func downloadCancel() {
        self.downloadStatus = .suspend
    }
    @discardableResult
    /// 启动下载（内部使用），返回自身以便链式调用。
    /// - Parameters:
    ///   - url: 下载 URL
    ///   - method: HTTP 方法
    ///   - parameters: 参数
    ///   - encoding: 编码
    ///   - headers: 头
    ///   - fileName: 自定义文件名
    fileprivate func download(
        _ url: String,
        method: SuhyHTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: SuhyParameterEncoding = URLEncoding.default,
        headers: SuhyHTTPHeaders? = nil,
        fileName: String?)
        -> DownloadTaskManager
    {
        let destination = downloadDestination(fileName)
        let resumeData = getResumeData(key)
        if let resumeData = resumeData {
            downloadRequest = NetworkEngine.default.download(resumingWith: resumeData, to: destination)
        } else {
            downloadRequest = NetworkEngine.default.download(url, method: method, parameters: parameters, encoding: encoding, headers: headers, to: destination)
        }
        downloadStatus = .downloading
        return self
    }
 
    /// 专用 Session，用于文件下载（默认 URLSessionConfiguration.default）
    lazy var manager: Session = NetworkEngine.default.defaultSession()
    
    /// 订阅此任务的下载进度，并返回自身以便链式调用。
    /// - Parameter progress: 进度回调（0.0 - 1.0）
    @discardableResult
    public func downloadProgress(progress: @escaping ((Double) -> Void)) -> DownloadTaskManager {
        downloadRequest?.downloadProgress(closure: { (pro) in
            self.saveProgress(pro.fractionCompleted)
            progress(pro.fractionCompleted)
        })
        return self
    }
    /// 以 closure 的形式返回下载完成或失败结果（兼容旧 API）。
    /// - Parameter completion: 完成回调，成功时返回本地文件 URL 字符串
    public func response(completion: @escaping (Alamofire.AFResult<String>)->()) {
        downloadRequest?.responseData(completionHandler: { (response) in
            switch response.result {
            case .success:
                self.downloadStatus = .complete
                let str = response.fileURL?.absoluteString
                if self.cancelCompletion != nil { self.cancelCompletion!() }
                completion(Alamofire.AFResult.success(str!))
            case .failure(let error):
                self.downloadStatus = .suspend
                self.saveResumeData(response.resumeData)
                if self.cancelCompletion != nil { self.cancelCompletion!() }
                completion(Alamofire.AFResult.failure(error))
            }
        })
    }

    /// Async/await 形式的响应方法。保持原有 closure API 兼容。
    /// - Returns: 下载完成后的文件 URL 字符串（若存在）
    /// - Throws: 下载失败的错误
    public func response() async throws -> String? {
        guard downloadRequest != nil else { throw DownloadError.noRequest }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
            self.downloadRequest?.responseData(completionHandler: { response in
                switch response.result {
                case .success:
                    self.downloadStatus = .complete
                    let str = response.fileURL?.absoluteString
                    if self.cancelCompletion != nil { self.cancelCompletion!() }
                    continuation.resume(returning: str)
                case .failure(let error):
                    self.downloadStatus = .suspend
                    self.saveResumeData(response.resumeData)
                    if self.cancelCompletion != nil { self.cancelCompletion!() }
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    /// 构建下载目标位置（保存到 Caches 目录），并记录文件路径到缓存。
    /// - Parameter fileName: 自定义文件名（可选）
    /// - Returns: `DownloadRequest.Destination` 回调
    private func downloadDestination(_ fileName: String?) -> DownloadRequest.Destination {
        let destination: DownloadRequest.Destination = { _, response in
            let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            if let fileName = fileName {
                let fileURL = cachesURL.appendingPathComponent(fileName)
                self.saveFilePath(fileURL.absoluteString)
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            } else {
                let fileURL = cachesURL.appendingPathComponent(response.suggestedFilename!)
                self.saveFilePath(fileURL.absoluteString)
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        }
        return destination
    }
    
    /// 保存当前下载进度到本地缓存（供查询使用）。
    func saveProgress(_ progress: Double) {
        if let progressData = "\(progress)".data(using: .utf8) {
            cacheDictionary["progress"] = progressData
            var model = CacheModel()
            model.dataDict = cacheDictionary
            CacheManager.default.setObject(model, forKey: key)
        }
    }
    
    /// 保存断点续传的 resumeData 到缓存
    func saveResumeData(_ data: Data?) {
        cacheDictionary["resumeData"] = data
        var model = CacheModel()
        model.dataDict = cacheDictionary
        CacheManager.default.setObject(model, forKey: key)
    }
    
    /// 保存已下载文件的本地路径到缓存
    func saveFilePath(_ filePath: String?) {
        if let filePathData = filePath?.data(using: .utf8) {
            cacheDictionary["filePath"] = filePathData
            var model = CacheModel()
            model.dataDict = cacheDictionary
            CacheManager.default.setObject(model, forKey: key)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}



/// 读取指定 key 的 resumeData（如果存在）
func getResumeData(_ url: String) -> Data? {
    let dic = getDictionary(url)
    if let data = dic["resumeData"] {
        return data
    }
    return nil
}

/// 读取指定 key 的保存进度
func getProgress(_ url: String) -> Double {
    let dic = getDictionary(url)
    if let progressData = dic["progress"],
        let progressString = String(data: progressData, encoding: .utf8),
        let progress = Double(progressString) {
        return progress
    }
    return 0
}

/// 读取指定 key 的文件路径（若存在）
func getFilePath(_ url: String) -> String? {
    let dic = getDictionary(url)
    if let filePathData = dic["filePath"],
        let filePath = String(data: filePathData, encoding: .utf8) {
        return filePath
    }
    return nil
}

/// 返回指定 key 保存的内部数据字典（progress/resumeData/filePath）
func getDictionary(_ url: String) -> Dictionary<String, Data> {
    if let dic = CacheManager.default.objectSync(forKey: url)?.dataDict {
        return dic
    }
    return [:]
}

