//
//  SuhyNetTools.swift
//  SuhyNetWorker
//
//  Created by suhongyi on 2022/10/20.
//

import UIKit
import CleanJSON

open class SuhyNetTools: NSObject {

    open class func DictionaryToJSON(dic:Any) -> Data {
        if (!JSONSerialization.isValidJSONObject(dic as! NSDictionary)) {
            print("无法解析出JSONString")
            return Data()
        }
        
        if let result = try? JSONSerialization.data(withJSONObject: dic, options: [])
        {
            return result
        }
        else{
            print("无法解析出JSONString")
            return Data()
        }
    }
    
    open class func toModel<T:Codable>(someModel:T.Type, dic:Any) throws -> T? {
        let json = SuhyNetTools.DictionaryToJSON(dic:dic)
        let decoder = CleanJSONDecoder()
        do {
            let temp = try decoder.decode(someModel, from: json)
            return temp
        } catch {
            print("解码失败: \(error)")
            return nil
        }
    }

}
