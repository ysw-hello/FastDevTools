
Pod::Spec.new do |s|

  s.name         = "FastDevTools"
  s.version      = "0.0.2"
  s.summary      = "一些帮助快速开发的工具类for iOS"
  s.homepage = "https://github.com/ysw-hello/FastDevTools"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "yanshiwei" => "shiwei_work@aliyun.com" }
  s.social_media_url   = "https://www.jianshu.com/u/2745b6c5b019"
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/ysw-hello/FastDevTools.git", :tag => "#{s.version}" }

  s.source_files  = '**/*.{h,m}', '**/**/*.{h,mm,cpp,hpp}' 
  s.libraries = 'c++'
  #s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/FastDevTools/Mp3Encode/Core' }

  s.resources = 'Mp3Encode/TestResource/test.pcm' #测试的资源文件
  s.ios.vendored_libraries = 'Mp3Encode/libLame/libmp3lame.a' #静态库
  #s.private_header_files = 'Mp3Encode/libLame/lame.h'
  s.requires_arc = true
  

end
