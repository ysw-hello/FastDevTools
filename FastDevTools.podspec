
Pod::Spec.new do |s|

  s.name         = "FastDevTools"
  s.version      = "0.0.1"
  s.summary      = "一些帮助快速开发的工具类for iOS"
  s.homepage = "https://github.com/ysw-hello/FastDevTools"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "yanshiwei" => "shiwei_work@aliyun.com" }
  s.social_media_url   = "https://www.jianshu.com/u/2745b6c5b019"
  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/ysw-hello/FastDevTools.git", :tag => "#{s.version}" }

  s.source_files  = "**/*.{h,m}"
  s.requires_arc = true
  # s.dependency "JSONKit", "~> 1.4"

end
