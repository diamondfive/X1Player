//
//  YZMoviePlayerCountdownView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  未开播倒计时视图

#import <UIKit/UIKit.h>

//倒计时计时器走完通知
extern NSString * const QNCountdownTimeoutNotification;

@interface YZMoviePlayerCountdownView : UIView

@property(nonatomic, strong)NSTimer *countDownTimer;

/**
 初始化倒计时视图

 @param startTimeInterval 开始时间戳
 @return 实例
 */
-(instancetype)initWithStartTimeInterval:(NSTimeInterval)startTimeInterval;



/**
 初始化倒计时视图

 @param startTimeInterval 开始时间戳
 @param currentTimeInterval 当前时间戳 由后台生成 防止手机当前时间戳被篡改
 @return 实例
 */
-(instancetype)initWithStartTimeInterval:(NSTimeInterval)startTimeInterval  currentTimeInterval:(NSTimeInterval)currentTimeInterval;


@end
