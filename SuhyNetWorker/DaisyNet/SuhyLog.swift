//
//  SuhyLog.swift
//  SuhyNetWorker
//
//  Created by Alucardulad on 2020/10/12.
//  Copyright © 2020年 Alucardulad. All rights reserved.
//
//  https://github.com/Alucardulad/SuhyNetWorker
//
import Foundation

// MARK: - log日志
func SuhyLog<T>( _ message: T, file: String = #file, method: String = #function, line: Int = #line){
    #if DEBUG
        print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(message)")
    #endif
}

