//
//  YZBrightnessView.h
//  亮度控制
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  亮度改变时显示的View

#import <UIKit/UIKit.h>
// 把单例方法定义为宏，使用起来更方便
#define YZBrightnessViewShared [YZMoivePlayerBrightnessView sharedBrightnessView]
@interface YZMoivePlayerBrightnessView : UIView
+ (instancetype)sharedBrightnessView;


@end
