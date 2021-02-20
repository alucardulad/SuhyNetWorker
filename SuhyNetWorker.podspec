Pod::Spec.new do |s|

s.name                  = 'SuhyNetWorker'
s.version               = '1.3.3'
s.license               = { :type => 'MIT'}
s.summary               = 'SuhyNetWorke网络模块带缓存'
s.description           = 'SuhyNetWorker网络模块带缓存.'
s.homepage              = 'https://github.com/alucardulad/SuhyNetWorker'
s.authors               = { 'alucardulad' => 'alucardulad@gmail.com' }
s.platform              = :ios, "10.0"
s.source                = { :git => 'https://github.com/alucardulad/SuhyNetWorker.git',:tag => s.version  }
s.requires_arc = true
s.dependency 'Cache', '>= 5.0.0'
s.dependency 'Alamofire', '>= 4.5.1'
s.dependency 'CleanJSON'
s.source_files = "SuhyNetWorker/SuhyNetWorker/*.swift" 
s.pod_target_xcconfig = { "SWIFT_VERSION" => "5.0" }
s.swift_version = '5.0'
end