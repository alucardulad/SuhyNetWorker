//
//  SuhyValue.swift
//  SuhyNetWorker
//
//  Created by Alucardulad on 2020/10/12.
//  Copyright © 2020年 Alucardulad. All rights reserved.
//
//  https://github.com/Alucardulad/SuhyNetWorker
//
import Foundation
import Alamofire


//// MARK: - Result
public struct SuhyValue<Value> {
    
    public let isCacheData: Bool
    public let result: Alamofire.AFResult<Value>
    public let response: HTTPURLResponse?
    
    init(isCacheData: Bool, result: Alamofire.AFResult<Value>, response: HTTPURLResponse?) {
        self.isCacheData = isCacheData
        self.result = result
        self.response = response
    }
}
