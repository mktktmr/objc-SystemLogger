//
//  SystemLogger.h
//  DemoSystemLogger
//
//  Created by Makoto Kitamura on 2016/01/21.
//  Copyright © 2016年 Makoto Kitamura. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SystemLogger : NSObject

/** 集計間隔 */
extern const NSInteger SYSTEM_MONITER_INTERVAL;

/**
 リソースの使用状況をログ出力する
 */
+ (void)dump;

@end
