//
//  SuhyNetWorker.swift
//  SuhyNetWorker
//
//  Created by 苏鸿翊 on 2021/2/4.
//

import Foundation
import Alamofire
import HandyJSON

/// api访问
/// - Parameters:
///   - api: api模型
///   - finishedCallback: 返回提示语句和返回原始的json数据
/// - Returns:
public func requestAPIModel(api:SuhyNetWorkerProtocol,finishedCallback:@escaping (_ result :SuhyNetWorkerResponse)->()){
    SuhyNetWorker.request(api.url, method:api.apiType, params: api.params, dynamicParams: api.dynamicParams, encoding: api.encoding, headers: api.headParams).cache(api.isNeedCache).responseCacheAndJson { (obj) in
        let result = SuhyNetWorkerResponse.init(value: obj, api: api)
        finishedCallback(result)
    }
}

/// api访问
/// - Parameters:
///   - api: api
///   - someModel: 将要转换的模型类型，需要遵守HandyJSON协议
///   - finishedCallback: 返回模型（模型数组或者单个模型），返回是否成功的提示语句
/// - Returns:
public func requestApiwithReturnModel<T:HandyJSON>(modelType:T.Type,api:SuhyNetWorkerProtocol,finishedCallback:@escaping (_ result : SuhyNetWorkerResponse,_ data : SuhyResponseEnum<T>) -> ())
{
    SuhyNetWorker.requestAPIModel(api: api) { (obj) in
        
        var requestDataModel:SuhyResponseEnum<T> = .none
        switch obj.value.result{
        case .success(let data):
            if let resultdic = data  as? [String : AnyObject]
            {
                let temp = SuhyNetTools.toModel(someModel:modelType, dic: resultdic)
                requestDataModel = .model(model: temp)
                finishedCallback(obj,requestDataModel)
            }else if let str = data as? String{
                requestDataModel = .txt(message: str)
                finishedCallback(obj,requestDataModel)
            }else{
                finishedCallback(obj,requestDataModel)
            }
            break
        case .failure( _):
            finishedCallback(obj,requestDataModel)
            break
        }
    }
}





