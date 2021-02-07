//
//  SuhyNetWorker.swift
//  SuhyNetWorker
//
//  Created by 苏鸿翊 on 2021/2/4.
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

public enum RequestModel {
    case model(model:modelClass)
    case List(ary:[modelClass])
    case none
}


/// api访问
/// - Parameters:
///   - api: api模型
///   - finishedCallback: 返回提示语句和返回数据
/// - Returns:
public func requestAPIModel(api:SuhyNetWorkerProtocol,finishedCallback:@escaping (SuhyValue<Any>)->()){
    SuhyNetWorker.request(api.url, method:api.apiType, params: api.params, dynamicParams: api.dynamicParams, encoding: api.encoding, headers: api.headParams).cache(api.isNeedCache).responseCacheAndJson { (obj) in
        finishedCallback(obj)
    }
}

/// aip访问，返回model和结果
/// - Parameters:
///   - api: api模型
///   - finishedCallback: 返回结果，和转换好了的模型
/// - Returns: 无
public func requestAPIModel(api:SuhyNetWorkerApiModelProtocol,finishedCallback:@escaping (_ result : SuhyValue<Any>,_ data : RequestModel) -> ()){
    SuhyNetWorker.requestApiwithReturnModel(someModel: api.mdoelType.self, api: api) { (result, lists) in
        finishedCallback(result,lists)
    }
}

/// api访问
/// - Parameters:
///   - api: api
///   - someModel: 将要转换的模型类型，需要遵守Codable协议
///   - finishedCallback: 返回模型（模型数组或者单个模型），返回是否成功的提示语句
/// - Returns:
fileprivate func requestApiwithReturnModel<T:modelClass>(someModel:T.Type,api:SuhyNetWorkerApiModelProtocol,finishedCallback:@escaping (_ result : SuhyValue<Any>,_ data : RequestModel) -> ())
{
    SuhyNetWorker.requestAPIModel(api: api) { (obj) in
        
        var requestDataModel:RequestModel = .none
        switch obj.result{
        case .success(let data):
            if let resultdic = data  as? [String : AnyObject]
            {
                if let tempdic = resultdic[api.objKeyStr] as? [String : AnyObject]{
                    let temp = SuhyNetWorker.toModel(someModel:someModel, dic: tempdic)
                    requestDataModel = .model(model: temp)
                }
                else if let tempArray = resultdic[api.objKeyStr] as? [[String : AnyObject]]{
                    var models = [T]()
                    for dic in tempArray {
                        let temp = SuhyNetWorker.toModel(someModel:someModel, dic: dic)
                        models.append(temp)
                    }
                    requestDataModel = .List(ary: models)
                }
                else{
                    requestDataModel = .none
                }
                finishedCallback(obj,requestDataModel)
            }
            break
        case .failure(let error):
            
            finishedCallback(obj,requestDataModel)
            
            break
        }
    }

}

func DictionaryToJSON(dic:Any) -> Data {
    if (!JSONSerialization.isValidJSONObject(dic as! NSDictionary)) {
        print("无法解析出JSONString")
        return Data()
    }
    return try! JSONSerialization.data(withJSONObject: dic, options: [])
}

func ArrayToJSON(array:[Any]) -> Data {
    if (!JSONSerialization.isValidJSONObject(array as! NSArray)) {
        print("无法解析出JSONString")
        return Data()
    }
    return try! JSONSerialization.data(withJSONObject: array, options: [])
}
 func toModel<T:Codable>(someModel:T.Type,dic:Any)->T {
    let json = SuhyNetWorker.DictionaryToJSON(dic:dic)
    let temp = try! JSONDecoder().decode(someModel, from: json)
    return temp
}
