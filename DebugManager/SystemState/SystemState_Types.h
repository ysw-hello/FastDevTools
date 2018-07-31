//
//  SystemState_Types.h
//  DebugController
//
//  Created by 闫士伟 on 2018/7/31.
//  Copyright © 2018年 com.ysw. All rights reserved.
//

#ifndef SystemState_Types_h
#define SystemState_Types_h

typedef NS_ENUM(NSUInteger, SystemState_LabelState) {
    kSystemState_LabelState_Good,
    kSystemState_LabelState_Warning,
    kSystemState_LabelState_Bad,
};

typedef NS_ENUM(NSUInteger, SystemState_LabelType) {
    kSystemState_LabelType_Memory,
    kSystemState_LabelType_CPU,
    kSystemState_LabelType_FPS,
};

#endif /* SystemState_Types_h */
