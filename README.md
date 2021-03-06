
## SuhyNetWorker

![](https://img.shields.io/badge/support-swift%204%2B-green.svg)   ![](https://img.shields.io/cocoapods/v/SuhyNetWorker.svg?style=flat)

对[Alamofire](https://github.com/Alamofire/Alamofire)与[Cache](https://github.com/hyperoslo/Cache)的封装实现对网络数据的缓存和如moya通过协议优雅的调用网络模块，可以存储JSON，String，Data。


## 使用

### 1. 网络请求

***注意： 如果你的参数中带有时间戳、token等变化的参数，这些参数需要写在`dynamicParams`参数中，避免无法读取缓存***
```swift
func request(
    _ url: String,
    method: HTTPMethod = .get,
    params: Parameters? = nil,
    dynamicParams: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil)
    -> RequestTaskManager
```

* 缓存数据只需要调用`.cache(true)`，不调用或者`.cache(false)`则不缓存
* 调用`responseCacheAndString`可以先读取缓存数据，再读取网络数据
* 通过`isCacheData`属性可以区分缓存数据还是网络数据
```swift
SuhyNetWorker.request(url, params: params).cache(true).responseCacheAndJson { value in
    switch value.result {
    case .success(let json):
        if value.isCacheData {
            print("我是缓存的")
        } else {
            print("我是网络的")
        }
    case .failure(let error):
        print(error)
    }
}
```

* 你也可以分别读取缓存数据和网络数据，如下代码
* 调用`cacheJson`方法获取缓存数据，调用`responseJson`获取网络数据

```swift
SuhyNetWorker.request(url, params: params).cache(true).cacheJson { json in
        print("我是缓存的")
    }.responseJson { response in
    print("我是网络的")
}
```
* 如果你不需要缓存，可以直接调用`responseJson`方法
```swift
SuhyNetWorker.request(url).responseString { response in
    switch response {
    case .success(let value): print(value)
    case .failure(let error): print(error)
    }
}
```

* 同理，如果你要缓存`Data`或者`String`，与`JSON`是相似的
```swift
/// 先读取缓存，再读取网络数据
SuhyNetWorker.request(url).cache(true).responseCacheAndString { value in }
SuhyNetWorker.request(url).cache(true).responseCacheAndData { value in }
```
```swift
/// 分别获取缓存和网络数据
SuhyNetWorker.request(url).cache(true).cacheString { string in
        print("我是缓存的")
    }.responseString { response in
    print("我是网络的")
}
```
* 取消请求
```swift
SuhyNetWorker.cancel(url, params: params)
```

* 清除缓存
```swift
/// 清除所有缓存
func removeAllCache(completion: @escaping (Bool)->())
/// 根据url和params清除缓存
func removeObjectCache(_ url: String, params: [String: Any]? = nil, completion: @escaping (Bool)->())
```

### 2. 下载

```swift
SuhyNetWorker.download(url).downloadProgress { progress in
        /// 下载进度
    }.response { response in
    /// 下载完成
}
```
* 如果正在下载中退出当前界面，再次进入时可以通过以下方法获取下载进度，并改变UI
```swift
SuhyNetWorker.downloadProgress(url) {
        print($0)
    }?.response(completion: { _ in
    print("下载完成")
})
```
* 获取下载状态
```swift
SuhyNetWorker.downloadStatus(url)
```

* 获取下载百分比
```swift
SuhyNetWorker.downloadPercent(url)
```

* 获取下载完成后文件所在位置
```swift
DSuhyNetWorker.downloadFilePath(url)
```

* 删除某个下载
```swift
SuhyNetWorker.downloadDelete(url)
```

* 取消某个下载
```swift
SuhyNetWorker.downloadCancel(url)
```

* 取消所有下载
```swift
SuhyNetWorker.downloadCancelAll()
```

### 3.SuhyNetWorkerProtocol协议协议封装网络请求
* SuhyNetWorkerProtocol协议
```swift
protocol SuhyNetWorkerProtocol {
    var baseUrl:String! { get } //根节点
    var url:String! { get }//子节点
    var apiType:HTTPMethod! { get }
    var params:[String: AnyObject]! { get }
    var headParams:HTTPHeaders! { get }
    var dynamicParams:[String: AnyObject]! { get }//可忽略的参数
    var isNeedCache:Bool! { get }//是否启用缓存策略
    var encoding:ParameterEncoding! { get }//转码格式
}
```
* 请求方法
```swift
func requestAPIModel(api:SuhyNetWorkerProtocol,finishedCallback:@escaping (SuhyValue<Any>)->())
```

* 实现`SuhyNetWorkerProtocol`后，封装方法函数
* 调用`requestAPIModel`可以实现如moya一样的网络封装。
* 通过`SuhyNetWorkerProtocol`协议，可以让你只关心调用协议。把网络层交给自定义的APIModel本身。


## Install
```
1.pod 'SuhyNetWorker'

2.pod install / pod update
```

## LICENSE

SuhyNetWorker is released under the MIT license. See [LICENSE](https://github.com/MQZHot/SuhyNetWorker/blob/master/LICENSE) for details.


