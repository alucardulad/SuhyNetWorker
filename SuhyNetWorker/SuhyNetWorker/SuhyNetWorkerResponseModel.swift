//
//  SuhyNetWorkerRequestModel.swift
//  SuhyNetWorker
//
//  Created by 苏鸿翊 on 2021/4/28.
//

import Foundation
import Alamofire

open class SuhyNetWorkerBaseModel:NSObject,Codable {

}

public typealias modelClass = SuhyNetWorkerBaseModel
/// api协议
public protocol SuhyNetWorkerProtocol {
    var baseUrl:String! { get }
    var url:String! { get }
    var apiType:HTTPMethod! { get }
    var params:[String: AnyObject]! { get }
    var headParams:HTTPHeaders! { get }
    var dynamicParams:[String: AnyObject]! { get }
    var isNeedCache:Bool! { get }
    var encoding:ParameterEncoding! { get }
}
  
public protocol SuhyNetWorkerWithModelProtocol{
    var mdoelType:modelClass.Type{ get }
    var objKeyStr:String!{ get }
}

public protocol SuhyNetWorkerApiModelProtocol:SuhyNetWorkerProtocol,SuhyNetWorkerWithModelProtocol{
    
}

public enum SuhyResponseEnum {
    case model(model:modelClass)
    case List(ary:[modelClass])
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
