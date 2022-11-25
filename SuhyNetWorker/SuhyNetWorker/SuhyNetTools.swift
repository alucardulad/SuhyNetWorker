//
//  SuhyNetTools.swift
//  SuhyNetWorker
//
//  Created by suhongyi on 2022/10/20.
//

import UIKit
import HandyJSON

open class SuhyNetTools: NSObject {
    open class func toModel<T:HandyJSON>(someModel:T.Type,dic:[String : AnyObject])->T {
        let temp = someModel.deserialize(from: dic)
        return temp!
    }

}
