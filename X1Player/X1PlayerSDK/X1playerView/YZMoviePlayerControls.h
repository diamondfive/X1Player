//
//  YZMoviePlayerControls.h
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  播放控制层,包含播放视图 控制层 重播视图

#import <UIKit/UIKit.h>
#import "YZMoviePlayerControlButton.h"
#import "YZMoviePlayerReplayView.h"
#import "YZMoviePlayerCoverView.h"
#import "YZMoviePlayerFloatView.h"

@class YZMoviePlayerController,X1PlayerView,YZMutipleDefinitionModel;

typedef enum {
    /** 不显示控制层 */
    YZMoviePlayerControlsStyleNone,
    
    /** 控制层全屏时自动调整为为YZMoviePlayerControlsStyleFullscreen 竖屏时自动调整为 YZMoviePlayerControlsStyleEmbedded  */
    YZMoviePlayerControlsStyleDefault,
    
    /** 控制层全屏时自动调整为为YZMoviePlayerControlsStyleLivePortrait 竖屏时自动调整为 YZMoviePlayerControlsStyleLiveLandscape  */
    YZMoviePlayerControlsStyleLive,
    
    /** 默认的录播竖屏样式 */
    YZMoviePlayerControlsStyleEmbedded,
    
    /** 默认的录播全屏样式 */
    YZMoviePlayerControlsStyleFullscreen,
    
      /** 默认的直播竖屏样式 */
    YZMoviePlayerControlsStyleLivePortrait,
    
     /** 默认的直播全屏样式 */
    YZMoviePlayerControlsStyleLiveLandscape,
    
    /** 小窗悬浮样式 */
    YZMoviePlayerControlsStyleFloatView
    

    
} YZMoviePlayerControlsStyle;

@interface YZMoviePlayerControlsBar : UIView

@property (nonatomic, strong) UIColor *color;

@end

@interface YZMoviePlayerControls : UIView

@property (nonatomic, weak) YZMoviePlayerController *moviePlayer;

/** 
 直播样式
 */
@property (nonatomic, assign) YZMoviePlayerControlsStyle style;


@property (nonatomic, strong) YZMoviePlayerControlsBar *topBar;
@property (nonatomic, strong) YZMoviePlayerControlsBar *bottomBar;
@property (nonatomic, strong) YZMoviePlayerFloatView *floatView; //悬浮小窗

@property (nonatomic, assign) BOOL isLocked; //是否锁屏

/**
 上下横幅颜色,默认无色
 */
@property (nonatomic, strong) UIColor *barColor;

/**
 上下横幅渐变遮罩层颜色,默认渐变黑色
 */
@property (nonatomic, strong) UIColor *barGradientColor;

/**
 横幅高度
 */
@property (nonatomic, assign) CGFloat barHeight;

/**
 控制层无操作时自动隐藏时间
 */
@property (nonatomic, assign) NSTimeInterval fadeDelay;

/** 
 当视频播放时，剩余时间递减
 Default value is NO.
 */
@property (nonatomic) BOOL timeRemainingDecrements;

/**
 是否在显示
 */
@property (nonatomic, readonly, getter = isShowing) BOOL showing;

// 标题
@property (nonatomic, strong) NSString *programTitle;

//是否需要展示重播视图
@property (nonatomic, assign) BOOL isNeedShowReplayView;

//是否需要竖屏情况下展示返回按钮
@property (nonatomic, assign) BOOL isNeedShowBackBtn;
//slider已播放部分颜色
@property (nonatomic, strong) UIColor *sliderMinimumTrackTintColor;
//slider缓冲部分颜色
@property (nonatomic, strong) UIColor *sliderMiddleTrackTintColor;
//slider未播放部分颜色
@property (nonatomic, strong) UIColor *sliderMaximumTrackTintColor;
//slider拖件image
@property (nonatomic, strong) UIImage *sliderThumbImage;

/** 
 默认的初始化方法
 */
- (id)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer style:(YZMoviePlayerControlsStyle)style;
//时间格式处理 显示在timeRemainingLabel上面
- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime;
//改变播放源,重设进度条及播放时间
- (void)resetMoveiPlayback:(BOOL) changeURL;
//playableDurationTimer调用的方法 每0.5S更新缓冲条的进度
- (void)monitorMoviePlayableDuration;
//3S超时视图
-(void)showDataTimeOutView;
-(void)removeDataTimeOutView;
// 设备旋转时调用的方法
-(void)fullscreenPressedWithOrientation:(UIInterfaceOrientation)orientation;

- (void)backBtnClick:(id)button;//点击返回按钮
- (void)fullscreenPressed:(id)button;//点击全屏按钮
- (void)playPausePressed:(id)button;//点击了开始暂停按钮
-(void)floatViewClick:(id)sender;//点击了悬浮小窗
-(void)closeFloatViewButtonClick:(UIButton *)sender;//点击了悬浮小窗关闭按钮

- (void)showControls:(void(^)(void))completion autoHide:(BOOL)autohide;
- (void)hideControls:(void(^)(void))completion;
//状态改变导致的UI改变
- (void)stateChangeCauseControlsUIChange;
//停止每秒更新时间label slider
-(void)stopDurationTimer;
//设置清晰度按钮
-(void)setupDefinitionBtn;

@end



