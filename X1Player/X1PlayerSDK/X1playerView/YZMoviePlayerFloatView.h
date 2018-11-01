//
//  YZMoivePlayerFloatView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/28.
//  Copyright © 2018年 channelsoft. All rights reserved.
// 悬浮小窗

#import <UIKit/UIKit.h>

@class YZMoviePlayerControlButton;

@class YZMoviePlayerControls;

@interface YZMoviePlayerFloatView : UIView

@property (nonatomic, strong) YZMoviePlayerControlButton *floatViewCloseBtn;

@property (nonatomic, assign) YZMoviePlayerControls *controls;


@end
