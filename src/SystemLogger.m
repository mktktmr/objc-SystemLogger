//
//  SystemLogger.m
//  DemoSystemLogger
//
//  Created by Makoto Kitamura on 2016/01/21.
//  Copyright © 2016年 Makoto Kitamura. All rights reserved.
//

#import "SystemLogger.h"

#import <mach/mach.h>

/* time_value_t型を msec に変換 */
#define tval2msec(tval) ((tval.seconds * 1000) + (tval.microseconds / 1000))

/** 計測したシステム情報を格納 */
struct system_info {
    NSInteger cpuUsage;
    NSInteger memoryUsage;
};

static struct system_info sysInfo;
static NSInteger preUserTime;
static NSInteger preSystemTime;

static BOOL hasHeader = NO;

const NSInteger SYSTEM_MONITER_INTERVAL = 1;

NSString * const LOG_DATETIME_FORMMAT = @"yyyy-MM-dd hh:mm:ss";

@implementation SystemLogger

+ (void)dump {
    [self systemInfo];
    
    if (!hasHeader) {
        NSLog(@"%s\tCPU usage (%%)\tmemory allocate (kB)", __func__);
        hasHeader = YES;
    }
    
    NSLog(@"%s\t%ld\t%ld",
          __func__,
          sysInfo.cpuUsage,
          sysInfo.memoryUsage / 1024);
}

/**
 CPU使用率を取得
 */
+ (void)systemInfo {
    
    struct mach_task_basic_info t_info;
    mach_msg_type_number_t t_info_count = MACH_TASK_BASIC_INFO_COUNT;
    
    if (task_info(current_task(), MACH_TASK_BASIC_INFO, (task_info_t)&t_info, &t_info_count)!= KERN_SUCCESS) {
        NSLog(@"%s(): Error in task_info(): %s",
              __FUNCTION__, strerror(errno));
    }
    
    // メモリ使用量取得
    sysInfo.memoryUsage = t_info.resident_size;
    
    // すでに終了したスレッドのCPU使用時間
    NSInteger userTime = tval2msec(t_info.user_time);
    NSInteger systemTime = tval2msec(t_info.system_time);
    
    // 実行中のスレッドのCPU使用時間(TASK_THREAD_TIMES_INFO_COUNT)を取得する。
    struct task_thread_times_info tti;
    t_info_count = TASK_THREAD_TIMES_INFO_COUNT;
    
    kern_return_t status = task_info(current_task(), TASK_THREAD_TIMES_INFO, (task_info_t)&tti, &t_info_count);
    if (status != KERN_SUCCESS) {
        NSLog(@"%s(): Error in task_info(): %s",
              __FUNCTION__, strerror(errno));
    }
    
    // 取得したCPU時間を、TASK_BASIC_INFOのCPU使用時間と合算する。
    userTime += tval2msec(tti.user_time);
    systemTime += tval2msec(tti.system_time);
    
    // 取得したCPU時間と前回取得したCPU時間の差分を取得
    NSUInteger diffUserTime = labs(userTime - preUserTime);
    NSUInteger diffSystemTime = labs(systemTime - preSystemTime);
    
    // 前回計測したデータを更新
    preUserTime = userTime;
    preSystemTime = systemTime;
    
    // CPU使用率を算出
    sysInfo.cpuUsage = (float)(diffUserTime + diffSystemTime) / (SYSTEM_MONITER_INTERVAL * 1000) * 100;
}

@end
