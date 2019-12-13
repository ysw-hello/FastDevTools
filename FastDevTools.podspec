
Pod::Spec.new do |s|

  s.name                = "FastDevTools"
  s.version             = "1.0.0"
  s.summary             = "一些帮助快速开发的工具类for iOS"
  s.homepage            = "https://github.com/ysw-hello/FastDevTools"
  s.license             = { :type => "MIT", :file => "LICENSE" }
  s.author              = { "yanshiwei" => "shiwei_work@aliyun.com" }
  s.social_media_url    = "https://www.jianshu.com/u/2745b6c5b019"
  s.platform            = :ios, "8.0"
  s.source              = { :git => "https://github.com/ysw-hello/FastDevTools.git", :tag => "#{s.version}" }
  s.requires_arc        = true
 
  #相册资源管理
  s.subspec 'AssetsSave' do |as|
    as.source_files = 'AssetsSave/*.{h,m}'
  end

  #水波纹动画
  s.subspec 'WaterWave' do |ww|
    ww.source_files = 'WaterWave/*.{h,m}'
  end

  #Mp3编码工具
  s.subspec 'Mp3Encode' do |me|
    me.source_files = 'Mp3Encode/**/*.{h,mm,cpp,hpp}'
    me.libraries = 'c++'
    me.ios.vendored_libraries = 'Mp3Encode/libLame/libmp3lame.a' #静态库
#    me.resources = 'Mp3Encode/TestResource/test.pcm' #测试的资源文件
  end
  
  #TextField样式定制
  s.subspec 'CustomTextField' do |tf|
    tf.source_files = 'CustomTextField/*.{h,m}'
  end

  #APM界面级无痕埋点
  s.subspec 'APMRecord' do |apm|
    apm.source_files = 'APM/*.{h,m}'
    apm.resources = 'APM/APM_VCBlackList.bundle' #黑名单界面<不采集apm数据>
    apm.dependency 'YYModel'
  end
    
  #DebugManager 本地沙盒可视化，FPS & CPU & 内存 性能可视化
  s.subspec 'DebugManager' do |dm|
    dm.source_files = 'DebugManager/**/*.{h,m}'
    
    dm.dependency 'FMDB'
    dm.dependency 'AFNetworking'
    dm.dependency 'GCDWebServer'
    dm.dependency 'GCDWebServer/WebUploader'
    dm.dependency 'GCDWebServer/WebDAV'
    dm.dependency 'FastDevTools/CustomTextField'
    dm.dependency 'FastDevTools/APMRecord'
    
    dm.resources = 'DebugManager/WebServer/WebDebugger/Resources/*.bundle'
    
    dm.libraries = 'resolv'
    dm.pod_target_xcconfig = {'HEADER_SEARCH_PATHS' => "$(SDK_DIR)/usr/include/libresolv"}
  end
  
  #Flex 第三方调试工具
  s.subspec 'DebugFlex' do |df|
    df.source_files = 'DebugFlex/*.{h,m}', 'DebugFlex/**/*.{h,m}'
    
    df.dependency 'FastDevTools/DebugManager'
  end

end
