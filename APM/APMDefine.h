//
//  APMDefine.h
//  FastDevTools
//
//  Created by TimmyYan on 2019/12/10.
//

#ifndef APMDefine_h
#define APMDefine_h

@class APMDataModel;

#import <YYModel/YYModel.h>
@protocol APMModelDelegate <NSObject>
+ (instancetype)customCreate;
@end

typedef void(^DeviceAPM_Handler)(APMDataModel *apmData);

#endif /* APMDefine_h */
