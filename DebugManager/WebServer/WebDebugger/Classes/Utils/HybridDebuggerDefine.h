//
//  HybridDebuggerDefine.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/8/21.
//

#ifndef HybridDebuggerDefine_h
#define HybridDebuggerDefine_h

#define Hybrid_DebuggerSwitch 1 // 调试模式开关
#define Hybrid_Debug __has_include(<FastDevTools/HybridDebuggerServerManager.h>) ? Hybrid_DebuggerSwitch : 0

#ifndef WSLog
    #define WSLog(format, ...)  do {\
                (NSLog)((@"[WebServer] " format), ##__VA_ARGS__); \
            } while (0)
#endif

static BOOL kGCDWebServer_logging_enabled = YES; // 调试日志开关

static NSString *const kHybridDebuggerCallBackFunction = @"window.debuggerBridge.__callback";
static NSString *const kHybridDebuggerActionKey = @"action";
static NSString *const kHybridDebuggerParamKey = @"param";

static NSString *const kHybridDebuggerInvokeRequestEvent = @"kHybridDebuggerInvokeRequestEvent";
static NSString *const kHybridDebuggerInvokeResponseEvent = @"kHybridDebuggerInvokeResponseEvent";

static NSString *const kHybridDebuggerBundleName = @"HybridDebugger";
static NSString *const kHybridDebuggerLogFile = @"__HybridLogger__.txt"; // server日志，本地文件名

//static NSString *const kHybridAutoTestCaseFileName = @"testcase.html"; // 自动化测试生成的示例html
//static NSString *const kHybridAutoTestDomain = @"http://www.baidu.com"; // 自动化测试示例域名

// 多行文字转字符串
#define HybridDebugger_ML(str) @#str

//# 字段含义说明；
//#   1. name 表示接口名称，是 invoke 或者 call 之后的第一个参数
//#   2. code 调用实例。注意，这里必须是可以真正运行的代码，因为这个字段会被作为测试用例，直接运行
//#           特别注意，当这个 hash 对象有 expectFunc 字段时，
//#           需要在 code 的源码里有回调去验证执行的结果是否符合预期。需要调用 window.report 接口。详细用例可参考 LocalStorage.getItem 字条
//#   3. discuss 描述接口的作用
//#   4. expect 表示执行 code 源码之后的效果或者结果，文字描述
//#   5. expectFunc ，可选项，表示 code 之后，可验证的数据，用于 自动化测试框架验证。
//#   6. autoTest ，可选项，默认为 false，表示可以响应自动化测试。false 表示不能响应，需要手动验证。 false 多见于那些页面跳转的逻辑接口
//
//# 注意其中，code 字段里的调用如果有 callback function，则需要自行验证，并且把结果,
//# 使用 window.report(res, eleId) 报告，其中可以用 eleId 参数。此参数代表测试用例关联的元素, 用来显示测试结果。
//#     其中，res 是 true、false、finish、tapApp、navBack、swipeDown、swipeLeft、sleep, 等的枚举值
//#     eleId 是 当前测试用例所在的行数。传入 eleId，无需修改。

#define debugger_concat(A, B) A##B
#define debugger_doc_log_prefix @"debugger_doc_for_"
#define debugger_doc_selector(name) NSSelectorFromString([NSString stringWithFormat:@"%@%@", debugger_doc_log_prefix, name])
// 定义 oc-doc，为自动化生成测试代码和自动化注释做准备
// 凡是可能多行的文字描述都用 @result,传入的数据需要有双引号，而不是@#result

 /**
  action介绍

  @param signature action名称
  @param desc action功能介绍
  */
#define debugger_doc_begin(signature, desc) +(NSDictionary *)debugger_concat(debugger_doc_for_, signature)\
{\
NSMutableArray *lst = [NSMutableArray arrayWithCapacity:3];\
NSMutableDictionary *docs = [@{\
@"name":@#signature,\
@"discuss":@desc\
} mutableCopy];

/**
 参数介绍

 @param field 参数名称
 @param desc 参数介绍
 */
#define debugger_doc_param(field, desc) [lst addObject:@{@#field:@desc}];

/**
 代码示例介绍

 @param code 代码示例
 */
#define debugger_doc_code(code) [docs setObject:@#code forKey:@"code"];

/**
 action调用后变化介绍

 @param result action正常实现的场景
 */
#define debugger_doc_code_expect(result) [docs setObject:@result forKey:@"expect"];

/**
 action文档记录结束
 
 @return 文档记录（字典）
 */
#define debugger_doc_end if(lst.count > 0){\
[docs setObject:lst forKey:@"param"];\
}\
return docs;\
}
//#define debugger_doc_code_expectFunc(result) [docs setObject:@result forKey:@"expectFunc"];
//#define debugger_doc_code_autoTest(result) [docs setObject:@result forKey:@"autoTest"];
//#define debugger_doc_return(type, desc) [docs setObject:@{@#type:@desc} forKey:@"return"];



#endif /* HybridDebuggerDefine_h */
