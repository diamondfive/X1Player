//
//  YZMoviePlayerControlAdditionView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  附加视图层(包含手势控制 清晰度切换视图)
//  手势包含包括 双击 上滑 下滑 左滑 右滑
//  2018.10.20 添加清晰度切换视图

#import <UIKit/UIKit.h>
#import "YZMutipleDefinitionModel.h"


@class YZMoviePlayerControls,YZMoviePlayerControlButton;

@interface YZMoviePlayerControlAdditionView : UIView

@property (nonatomic, weak)YZMoviePlayerControls *controls;

@property (nonatomic, strong) NSArray<YZMutipleDefinitionModel *>*mediasourceDefinitionArr;

/** 锁屏按钮 */
@property (nonatomic, strong) YZMoviePlayerControlButton *lockBtn;

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

/** 清晰度切换视图 */
@property (nonatomic, strong) UIView *definitionView;
@property (nonatomic, strong) UITableView *definitionTableView;

/**
 创建手势
 */
- (void)createGesture;


/**
 点击了清晰度选择按钮
 */
-(void)clickDefinitioBtn;



@end
