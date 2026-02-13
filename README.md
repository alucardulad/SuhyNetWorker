# SuhyNetWorker

![Support](https://img.shields.io/badge/support-swift%204%2B-green.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2011.0%2B-blue.svg)
![Swift](https://img.shields.io/badge/swift-5.0%2B-orange.svg)
![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)
![Version](https://img.shields.io/badge/version-1.5.6-purple.svg)

<div align="center">

**优雅的 iOS 网络层封装**
**支持请求缓存、下载管理、Moya 风格协议调用**

[功能特性](#-功能特性) • [快速开始](#-快速开始) • [使用示例](#-使用示例) • [API 文档](#-api-文档) • [贡献指南](#-贡献指南)

</div>

---

## 📖 项目简介

SuhyNetWorker 是一个基于 **Alamofire** 和 **Cache** 封装的 iOS 网络层框架，类似 Moya 的 API 调用方式。它提供了简洁优雅的 API，支持智能缓存、下载管理、网络请求封装等功能，帮助开发者快速构建稳定高效的网络层。

### 核心特性

- ✅ **智能缓存策略** - 支持缓存和网络的混合使用
- ✅ **Moya 风格封装** - 类似 Moya 的协议式 API 调用
- ✅ **下载管理** - 支持进度监听、断点续传、取消/删除
- ✅ **链式调用** - 流畅的 Builder 模式 API 设计
- ✅ **类型安全** - 基于泛型和 Codable 的类型安全
- ✅ **异步/await 支持** - 现代异步编程方式
- ✅ **URL + params 缓存 Key** - 智能缓存 Key 生成

---

## 🎯 功能特性

### 1. 网络请求 + 智能缓存

支持同时获取缓存和网络数据，避免缓存失效问题。

```swift
// 先读取缓存，再读取网络数据
SuhyNetWorker.request(url).cache(true).responseCacheAndJson { value in
    if value.isCacheData {
        print("我是缓存的 ✅")
    } else {
        print("我是网络的 📡")
    }
}

// 分别获取缓存和网络数据
SuhyNetWorker.request(url).cache(true)
    .cacheJson { json in print("缓存: \(json)") }
    .responseJson { response in print("网络: \(response)") }
```

**支持的数据类型：**
- JSON (`responseCacheAndJson` / `cacheJson`)
- String (`responseCacheAndString` / `cacheString`)
- Data (`responseCacheAndData` / `cacheData`)

### 2. Moya 风格的协议封装

通过协议定义 API，统一管理网络层。

```swift
// 定义 API 协议
struct UserAPI: SuhyNetWorkerProtocol {
    var baseUrl: String = "https://api.example.com"
    var url: String = "/user/profile"
    var apiType: HTTPMethod = .get
    var params: [String: Any] = ["id": 123]
    var headParams: HTTPHeaders = []
    var dynamicParams: [String: Any] = ["timestamp": Date().timeIntervalSince1970]
    var isNeedCache: Bool = true
    var encoding: ParameterEncoding = URLEncoding.default
}

// 调用 API
SuhyNetWorker.requestAPIModel(api: UserAPI()) { response in
    if let data = response.value.result.value as? [String: Any] {
        print("用户数据: \(data)")
    }
}
```

**重要提示：** `dynamicParams` 用于包含时间戳、token 等变化的参数，避免缓存失效。

### 3. 下载管理

支持下载进度监听、断点续传、暂停/恢复、取消下载。

```swift
// 基础下载
SuhyNetWorker.download(url)
    .downloadProgress { progress in
        let percent = Int(progress.fractionCompleted * 100)
        print("下载进度: \(percent)%")
    }
    .response { response in
        print("下载完成: \(response)")
    }

// 异步下载（async/await）
let fileUrl = try await DownloadManager.default.downloadAsync(url)
print("文件保存路径: \(fileUrl)")

// 下载进度查询
let progress = SuhyNetWorker.downloadPercent(url)
let status = SuhyNetWorker.downloadStatus(url)

// 取消下载
SuhyNetWorker.downloadCancel(url)
SuhyNetWorker.downloadCancelAll()

// 删除下载
SuhyNetWorker.downloadDelete(url)
```

### 4. 灵活的参数管理

支持固定参数、动态参数、自定义超时。

```swift
// 固定参数 + 动态参数
SuhyNetWorker.request(
    url,
    method: .post,
    params: ["api_key": "xxx", "version": "1.0"],  // 固定参数
    dynamicParams: ["token": token, "timestamp": Date().timeIntervalSince1970]  // 动态参数
).cache(true).responseJson { response in
    // 处理响应
}

// 设置全局超时
RequestManager.default.timeoutIntervalForRequest(30)  // 30 秒
```

### 5. 缓存管理

```swift
// 清除所有缓存
SuhyNetWorker.removeAllCache { isSuccess in
    print("清除缓存: \(isSuccess)")
}

// 根据条件清除缓存
SuhyNetWorker.removeObjectCache(url, params: ["id": 123]) { isSuccess in
    print("清除指定缓存: \(isSuccess)")
}
```

---

## 🚀 快速开始

### 安装

#### 1. CocoaPods

```ruby
pod 'SuhyNetWorker'
```

然后运行：
```bash
pod install
# 或更新
pod update
```

#### 2. Swift Package Manager（SPM）

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/alucardulad/SuhyNetWorker.git", from: "1.5.6")
]
```

或在 Xcode → File → Add Packages 中添加。

### 初始化

无需初始化，直接使用全局接口：

```swift
import SuhyNetWorker

// 开始使用
let response = try await SuhyNetWorker.request(url).responseJson()
```

---

## 📚 使用示例

### 示例 1：获取用户信息（带缓存）

```swift
struct UserAPI: SuhyNetWorkerProtocol {
    var baseUrl: String = "https://api.example.com"
    var url: String = "/user/profile"
    var apiType: HTTPMethod = .get
    var params: [String: Any] = [:]
    var dynamicParams: [String: Any] = ["timestamp": Date().timeIntervalSince1970]
    var headParams: HTTPHeaders = [
        "Authorization": "Bearer \(token)"
    ]
    var isNeedCache: Bool = true
    var encoding: ParameterEncoding = URLEncoding.default
}

class UserService {
    func getUser() async throws -> User? {
        let response = try await SuhyNetWorker.requestAPIModel(api: UserAPI())
        
        if case .success(let data) = response.value.result {
            return try User(json: data)
        }
        return nil
    }
}
```

### 示例 2：文件下载（带进度）

```swift
func downloadFile(url: String, fileName: String) async {
    do {
        let filePath = try await DownloadManager.default.downloadAsync(
            url,
            fileName: fileName
        )
        print("文件下载完成: \(filePath)")
    } catch {
        print("下载失败: \(error)")
    }
}

// 带进度监听
SuhyNetWorker.download(url)
    .downloadProgress { progress in
        let progressStr = String(format: "%.1f", progress.fractionCompleted * 100)
        print("下载进度: \(progressStr)%")
    }
    .response { response in
        switch response {
        case .success(let value):
            print("下载成功: \(value)")
        case .failure(let error):
            print("下载失败: \(error)")
        }
    }
```

### 示例 3：混合缓存和网络数据

```swift
struct ProductAPI: SuhyNetWorkerProtocol {
    var baseUrl: String = "https://api.example.com"
    var url: String = "/product/list"
    var apiType: HTTPMethod = .get
    var params: ["page": 1, "size": 20]
    var dynamicParams: ["timestamp": Date().timeIntervalSince1970]
    var isNeedCache: Bool = true
    var encoding: URLEncoding.default
}

// 调用
SuhyNetWorker.requestAPIModel(api: ProductAPI()) { response in
    switch response.value.result {
    case .success(let data):
        // 检查是缓存还是网络数据
        if response.value.isCacheData {
            print("从缓存获取数据 ⏪")
        } else {
            print("从网络获取数据 📡")
        }
        
        // 解析数据
        if let list = data as? [String: Any] {
            print("产品列表: \(list)")
        }
    case .failure(let error):
        print("请求失败: \(error)")
    }
}
```

### 示例 4：取消请求

```swift
// 取消单个请求
SuhyNetWorker.cancel(url, params: ["id": 123])

// 清除缓存
SuhyNetWorker.removeObjectCache(url, params: ["id": 123])
```

---

## 📖 API 文档

### 网络请求 API

#### `SuhyNetWorker.request(_ url: String, ...)`

创建网络请求管理器，支持链式调用。

**参数：**
- `url`: 请求 URL
- `method`: HTTP 方法（默认 `.get`）
- `params`: 固定参数
- `dynamicParams`: 动态参数（会覆盖固定参数）
- `encoding`: 参数编码方式（默认 `URLEncoding.default`）
- `headers`: HTTP 头

**返回：** `RequestTaskManager`

**示例：**
```swift
SuhyNetWorker.request(url)
    .cache(true)
    .responseJson { response in }
```

#### `SuhyNetWorker.requestAPIModel(api: ...)`

Moya 风格的 API 调用。

**参数：**
- `api`: 实现 `SuhyNetWorkerProtocol` 的对象
- `finishedCallback`: 回调函数

**示例：**
```swift
SuhyNetWorker.requestAPIModel(api: UserAPI()) { response in }
```

### 缓存相关 API

#### `.cache(_ isCache: Bool)`

设置是否启用缓存。

**示例：**
```swift
SuhyNetWorker.request(url).cache(true)
```

#### `.responseCacheAndJson(handler: ...)`

先读取缓存，再读取网络数据。

**示例：**
```swift
SuhyNetWorker.request(url).cache(true).responseCacheAndJson { value in
    if value.isCacheData {
        print("缓存数据")
    }
}
```

#### `.cacheJson(handler: ...)`

仅获取缓存数据。

#### `.responseJson(handler: ...)`

仅获取网络数据。

### 下载管理 API

#### `SuhyNetWorker.download(_ url: String, ...)`

创建下载任务管理器。

**参数：**
- `url`: 下载 URL
- `fileName`: 自定义文件名（可选）

**返回：** `DownloadTaskManager`

**示例：**
```swift
SuhyNetWorker.download(url)
    .downloadProgress { progress in }
    .response { response in }
```

#### `SuhyNetWorker.downloadPercent(_ url: String)`

获取下载进度（0.0 ~ 1.0）。

#### `SuhyNetWorker.downloadStatus(_ url: String)`

获取下载状态（进行中/已完成/已取消）。

#### `SuhyNetWorker.downloadCancel(_ url: String)`

取消指定 URL 的下载。

#### `SuhyNetWorker.downloadCancelAll()`

取消所有下载。

#### `SuhyNetWorker.downloadDelete(_ url: String)`

删除指定下载的文件。

#### `SuhyNetWorker.removeAllCache(handler: ...)`

清除所有缓存。

#### `SuhyNetWorker.removeObjectCache(_ url: String, ...)`

清除指定 URL 的缓存。

---

## 🏗️ 项目结构

```
SuhyNetWorker/
├── SuhyNetWorker/
│   ├── SuhyNetWorker.swift          # 主入口
│   ├── RequestManager.swift         # 请求管理器
│   ├── NetworkEngine.swift          # 网络引擎
│   ├── CacheManager.swift           # 缓存管理器
│   ├── DownloadManager.swift        # 下载管理器
│   ├── CacheKey.swift               # 缓存 Key 生成
│   ├── SuhyNet.swift                # 工具类
│   ├── SuhyNetTools.swift           # 辅助工具
│   ├── SuhyNetWorkerResponseModel.swift  # 响应模型
│   ├── SuhyValue.swift              # 通用值包装
│   └── SuhyLog.swift                # 日志工具
├── Example/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── ViewController.swift
│   └── Assets.xcassets/
├── SuhyNetWorker.podspec            # CocoaPods 配置
├── Podfile                          # CocoaPods 依赖
└── README.md
```

### 核心模块说明

| 模块 | 职责 |
|------|------|
| **RequestManager** | 管理所有网络请求任务，支持请求复用 |
| **CacheManager** | 管理本地缓存（内存 + 磁盘） |
| **DownloadManager** | 管理文件下载任务 |
| **NetworkEngine** | 封装 Alamofire 请求引擎 |
| **SuhyNet** | 主入口，提供全局 API |

---

## ⚙️ 配置选项

### 缓存过期策略

```swift
enum SuhyExpiry {
    case never                          // 永不过期
    case seconds(TimeInterval)          // 指定秒数后过期
    case date(Date)                     // 指定日期后过期
}

// 配置缓存过期时间
CacheManager.default.expiryConfiguration(expiry: .seconds(3600))  // 1 小时后过期
```

### 超时设置

```swift
// 全局超时设置
RequestManager.default.timeoutIntervalForRequest(30)  // 30 秒
```

---

## 🔧 高级用法

### 自定义缓存 Key

```swift
// 当前缓存 Key 生成方式
func cacheKey(_ url: String, _ params: Parameters?, _ dynamicParams: Parameters?) -> String {
    var components = [url]
    let allParams = (params ?? []) + (dynamicParams ?? [])
    if !allParams.isEmpty {
        components.append("\(allParams)")
    }
    return components.joined(separator: "&")
}
```

### 监听下载进度

```swift
// 获取下载进度
SuhyNetWorker.downloadProgress(url) { progress in
    print("下载进度: \(progress.fractionCompleted)")
}

// 实时更新 UI
let progressView = UIProgressView()
SuhyNetWorker.download(url)
    .downloadProgress { progress in
        DispatchQueue.main.async {
            progressView.progress = Float(progress.fractionCompleted)
        }
    }
```

---

## ⚠️ 注意事项

1. **dynamicParams 重要**：包含时间戳、token 等变化的参数必须放在 `dynamicParams` 中，否则缓存会失效。

2. **缓存 Key 生成**：缓存 Key 基于 URL + params + dynamicParams 生成，参数顺序会影响缓存结果。

3. **请求取消**：使用 `cancel()` 取消请求后，缓存不会自动清除，需要手动调用 `removeObjectCache()`。

4. **下载任务管理**：下载任务使用 `Dictionary` 存储，长时间运行应用可能导致内存占用增加。

5. **线程安全**：部分方法在多线程环境下使用，建议在主线程更新 UI。

---

## 📄 许可证

本项目采用 [MIT 许可证](LICENSE)。

```
Copyright (c) 2020-2025 SuhyNetWorker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 提交 Pull Request 的步骤

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 使用 Swift 5.0+ 语法
- 遵循 Swift API Design Guidelines
- 添加适当的注释和文档
- 编写单元测试

---

## 📞 联系方式

- **作者**: alucardulad
- **邮箱**: alucardulad@gmail.com
- **主页**: https://github.com/alucardulad/SuhyNetWorker

---

## 🌟 Star History

如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！

<div align="center">

**Made with ❤️ by alucardulad**

</div>
