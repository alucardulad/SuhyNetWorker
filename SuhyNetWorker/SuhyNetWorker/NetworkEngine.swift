//
//  NetworkEngine.swift
//  SuhyNetWorker
//
//  Created by GitHub Copilot on refactor.
//
import Foundation
import Alamofire

/// 抽象网络引擎协议，封装底层网络实现（例如 Alamofire）
public protocol NetworkEngineProtocol {
    func request(_ url: String, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?) -> DataRequest
    func request(_ urlRequest: URLRequestConvertible) -> DataRequest
    func download(_ url: String, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?, to destination: DownloadRequest.Destination) -> DownloadRequest
    func download(resumingWith resumeData: Data, to destination: DownloadRequest.Destination) -> DownloadRequest
    func makeSession(timeout: TimeInterval?) -> Session
    func defaultSession() -> Session
}

/// Alamofire 的默认实现
public final class AlamofireNetworkEngine: NetworkEngineProtocol {
    public static let `default` = AlamofireNetworkEngine()
    private init() {}

    private lazy var session: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = HTTPHeaders.default
        return Session(configuration: configuration)
    }()

    public func defaultSession() -> Session {
        return session
    }

    public func makeSession(timeout: TimeInterval?) -> Session {
        let configuration = URLSessionConfiguration.default
        if let t = timeout {
            configuration.timeoutIntervalForRequest = t
        }
        configuration.headers = HTTPHeaders.default
        return Session(configuration: configuration)
    }

    public func request(_ url: String, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?) -> DataRequest {
        return session.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }

    public func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        return session.request(urlRequest)
    }

    public func download(_ url: String, method: HTTPMethod, parameters: Parameters?, encoding: ParameterEncoding, headers: HTTPHeaders?, to destination: DownloadRequest.Destination) -> DownloadRequest {
        return session.download(url, method: method, parameters: parameters, encoding: encoding, headers: headers, to: destination)
    }

    public func download(resumingWith resumeData: Data, to destination: DownloadRequest.Destination) -> DownloadRequest {
        return session.download(resumingWith: resumeData, to: destination)
    }
}

/// 默认全局网络引擎实例（可替换为其他实现以解除对 Alamofire 的强耦合）
public enum NetworkEngine {
    public static var `default`: NetworkEngineProtocol = AlamofireNetworkEngine.default
}
