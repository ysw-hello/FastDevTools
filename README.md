# FastDevTools

## 集成方式：Cocoapods 
#### 整个库集成:
pod 'FastDevTools’

#### 调试工具组件集：<包含：业务定制 & 网络分析 & WebServer(日志/图表可视化、Hybrid调试) & APM & 应用内数据抓取 & 沙盒调试 & FLEX工具集兼容>
pod 'FastDevTools/DebugManager'
##### FLEX定制化集成:
pod 'FastDevTools/DebugFlex' <Flex模块，仅供线下调试使用>

#### 性能数据采集上报:<无痕/定制植入、数据采样/持续采集>
pod 'FastDevTools/APMRecord'

#### 相册资源存储管理:保存图片或视频到系统相册及是否添加到自创建的相册中
pod 'FastDevTools/AssetsSave’

#### 水波纹动画:
pod 'FastDevTools/WaterWave’

#### 音频文件Mp3编码:
pod 'FastDevTools/Mp3Encode’

#### 定制TextField样式：（号码显示格式，placeHolder样式，输入区域偏移等）
pod 'FastDevTools/CustomTextField'

