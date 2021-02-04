//
//  SuhyNetWorker.swift
//  SuhyNetWorker
//
//  Created by 苏鸿翊 on 2021/2/4.
//

import Foundation
import Alamofire

/// api协议
protocol SuhyNetWorkerProtocol {
    var baseUrl:String! { get }
    var url:String! { get }
    var apiType:HTTPMethod! { get }
    var params:[String: AnyObject]! { get }
    var headParams:HTTPHeaders! { get }
    var dynamicParams:[String: AnyObject]! { get }
    var isNeedCache:Bool! { get }
    var encoding:ParameterEncoding! { get }
}


/// api访问
/// - Parameters:
///   - api: api模型
///   - finishedCallback: 返回提示语句和返回数据
/// - Returns:
func requestAPIModel(api:SuhyNetWorkerProtocol,finishedCallback:@escaping (SuhyValue<Any>)->()){
    SuhyNetWorker.request(api.url, method:api.apiType, params: api.params, dynamicParams: api.dynamicParams, encoding: api.encoding, headers: api.headParams).responseCacheAndJson { (obj) in
        finishedCallback(obj)
    }
}
