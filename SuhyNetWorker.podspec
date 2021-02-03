Pod::Spec.new do |s|

s.name                  = 'SuhyNetWorker'
s.version               = '1.0.0'
s.license               = { :type => 'MIT'}
s.summary               = 'SuhyNetWorke网络模块带缓存'
s.description           = 'SuhyNetWorker网络模块带缓存.'
s.homepage              = 'https://github.com/alucardulad/SuhyNetWorker'
s.authors               = { 'alucardulad' => 'alucardulad@gmail.com' }
s.ios.deployment_target = '9.0'
s.source                = { :git => 'https://github.com/alucardulad/SuhyNetWorker.git',:tag => s.version  }
s.requires_arc = true
s.source_files = 'DaisyNet/DaisyNet/*.{swift}'
end