//
//  YZMoivePlayerReplayView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/18.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  重播视图

#import <UIKit/UIKit.h>
#import "YZMoviePlayerControlButton.h"

@class YZMoviePlayerController;


@interface YZMoivePlayerReplayView : UIView

@property (nonatomic, strong) YZMoviePlayerControlButton *replayBtn;

@property (nonatomic, strong) UILabel *replayLabel;


@property (nonatomic, strong) YZMoviePlayerControlButton *backBtn;

@property (nonatomic, strong) YZMoviePlayerControlButton *fullscreenBtn;

@property (nonatomic, strong) YZMoviePlayerControlButton *floatViewCloseBtn;


@property (nonatomic, weak) YZMoviePlayerController *moviePlayer;


-(instancetype)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer;

/**
 展示重播视图

 */
-(void)showReplayViewWithBackBtn:(BOOL)isNeedShow;


/**
 展示小窗关闭按钮
 */
-(void)showFloatViewCloseBtn:(BOOL)isNeedShow;
@end
