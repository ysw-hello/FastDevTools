
Pod::Spec.new do |s|

  s.name         = "FastDevTools"
  s.version      = "0.9.0"
  s.summary      = "一些帮助快速开发的工具类for iOS"
  s.homepage     = "https://github.com/ysw-hello/FastDevTools"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "yanshiwei" => "shiwei_work@aliyun.com" }
  s.social_media_url   = "https://www.jianshu.com/u/2745b6c5b019"
  s.platform           = :ios, "8.0"
  s.source             = { :git => "https://github.com/ysw-hello/FastDevTools.git", :tag => "#{s.version}" }
  s.requires_arc       = true 
 
  #相册资源管理
  s.subspec 'AssetsSave' do |ss|
    ss.source_files = 'AssetsSave/*.{h,m}'
  end

  #水波纹动画
  s.subspec 'WaterWave' do |ss|
    ss.source_files = 'WaterWave/*.{h,m}'
  end

  #Mp3编码工具
  s.subspec 'Mp3Encode' do |ss|
    ss.source_files = 'Mp3Encode/**/*.{h,mm,cpp,hpp}'
    ss.libraries = 'c++'
    ss.ios.vendored_libraries = 'Mp3Encode/libLame/libmp3lame.a' #静态库
    ss.resources = 'Mp3Encode/TestResource/test.pcm' #测试的资源文件
  end
  
  #TextField样式定制
  s.subspec 'CustomTextField' do |ss|
    ss.source_files = 'CustomTextField/*.{h,m}'
  end

  #DebugManager 本地沙盒可视化，FPS & CPU & 内存 性能可视化
  s.subspec 'DebugManager' do |ss|
    ss.source_files = 'DebugManager/DebugController.{h,m}' , 'DebugManager/**/*.{h,m}' , 'DebugManager/**/**/*.{h,m}'
    ss.dependency 'FMDB'
    ss.dependency 'AFNetworking'
    ss.dependency 'GCDWebServer'
    ss.dependency 'GCDWebServer/WebUploader'
    ss.dependency 'GCDWebServer/WebDAV'
    ss.dependency 'FastDevTools/CustomTextField'
    ss.libraries = 'resolv'
  end

end
