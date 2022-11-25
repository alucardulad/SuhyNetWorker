//
//  SuhyNetWorkerRequestModel.swift
//  SuhyNetWorker
//
//  Created by 苏鸿翊 on 2021/4/28.
//

import Foundation
import Alamofire
import HandyJSON

public typealias SuhyHTTPMethod = HTTPMethod
public typealias SuhyHTTPHeaders = HTTPHeaders
public typealias SuhyParameterEncoding = ParameterEncoding

/// api协议
public protocol SuhyNetWorkerProtocol {
    ///根网址
    var baseUrl:String! { get }
    ///网址
    var url:String! { get }
    ///get,post
    var apiType:SuhyHTTPMethod! { get }
    ///参数
    var params:[String: AnyObject]! { get }
    ///head参数
    var headParams:SuhyHTTPHeaders! { get }
    /// 如果你的参数中带有时间戳、token等变化的参数，这些参数需要写在dynamicParams参数中，避免无法读取缓存
    var dynamicParams:[String: AnyObject]! { get }
    ///是否需要缓存
    var isNeedCache:Bool! { get }
    ///转码
    var encoding:SuhyParameterEncoding! { get }
}

public struct SuhyNetWorkerModelsApi<T:HandyJSON>:SuhyNetWorkerProtocol{
    public var baseUrl: String!
    
    public var url: String!
    
    public var apiType: SuhyHTTPMethod!
    
    public var params: [String : AnyObject]!
    
    public var headParams: SuhyHTTPHeaders!
    
    public var dynamicParams: [String : AnyObject]!
    
    public var isNeedCache: Bool!
    
    public var encoding: SuhyParameterEncoding!
    
    var modelType:T
}

public enum SuhyResponseEnum<T> {
    ///单个模型
    case model(model:T)
    ///空模型
    case none
}

protocol SuhyNetWorkerResponseProtocol{
    var value:SuhyValue<Any> { get }
    var api:SuhyNetWorkerProtocol{ get }
}

public struct SuhyNetWorkerResponse: SuhyNetWorkerResponseProtocol {
    public var value: SuhyValue<Any>
    public var api: SuhyNetWorkerProtocol
}
