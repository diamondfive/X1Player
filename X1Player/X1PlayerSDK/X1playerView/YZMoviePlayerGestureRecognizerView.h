//
//  QNGestureRecognizerView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  手势控制层 包括 双击 上滑 下滑 左滑 右滑

#import <UIKit/UIKit.h>

@class YZMoviePlayerControls;

@interface YZMoviePlayerGestureRecognizerView : UIView

@property (nonatomic, weak)YZMoviePlayerControls *controls;




/** 单击 */
@property (nonatomic, strong) UITapGestureRecognizer *singleTap;
/** 双击 */
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
/** 滑动 */
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

/** 用来保存pan手势快进的总时长 */
@property (nonatomic, assign) float panMoveTotalTime;


/** 是否在调节音量 */
@property (nonatomic, assign) BOOL isVolume;

//直播不展示快进快退 录播展示
@property (nonatomic, assign) BOOL isNeedShowFastforward;

/**
 创建手势
 */
- (void)createGesture;



@end
