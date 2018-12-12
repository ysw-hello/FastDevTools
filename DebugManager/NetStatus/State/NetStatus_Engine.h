//
//  NetStatus_Engine.h
//  NetStatus_Demo
//
//  Created by TimmyYan on 2018/11/28.
//  Copyright © 2018年 com.zuoyebang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetStatus_Defines.h"

@interface NetStatus_Engine : NSObject

@property (nonatomic, readonly, assign) NSStateID currentStateID;
@property (nonatomic, readonly, strong) NSArray *allStates;

- (void)start;

- (NSUInteger)receiveInput:(NSDictionary *)dic;
- (BOOL)isCurrentStateAvailable;

@end
