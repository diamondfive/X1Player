//
//  YZMoviePlayerController.h
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  视频播放控制器

#import <MediaPlayer/MPMoviePlayerController.h>
#import "YZMoviePlayerControls.h"
#import "X1Player.h"
#import "YZMoivePlayerCoverView.h"
#import "YZMoivePlayerReplayView.h"

extern NSString * const YZMoviePlayerWillEnterFullscreenNotification;
extern NSString * const YZMoviePlayerDidEnterFullscreenNotification;
extern NSString * const YZMoviePlayerWillExitFullscreenNotification;
extern NSString * const YZMoviePlayerDidExitFullscreenNotification;
//播放完成的回调
extern NSString * const YZMoviePlayerOnCompletionNotification;
//播放状态变化通知
extern NSString * const YZMoviePlayerMediaStateChangedNotification;
//播放地址变更
extern NSString * const YZMoviePlayerContentURLDidChangeNotification;

@class X1PlayerView;
@protocol YZMoviePlayerControllerDelegate <NSObject>
@optional
//缓冲超时
- (void)yzMoviePlayerControllerMovieTimedOut;
//竖屏情况下点击返回按钮
- (void)yzMoviePlayerControllerOnClickBackBtn;
//悬浮小窗被点击
- (void)yzMoviePlayerControllerOnClickFloatView;
//悬浮小窗叉号按钮
- (void)yzMoviePlayerControllerOnClickCloseFloatViewBtn;
@required
//切换横屏的回调
- (void)yzMoviePlayerControllerMoviePlayerWillEnterFullScreen;
//切换竖屏的回调
- (void)yzMoviePlayerControllerMoviePlayerWillExitFullScreen;
@end


@interface YZMoviePlayerController : MPMoviePlayerController

//视频数据源url
@property (nonatomic, strong) NSString *mediasource;
//视频清晰度字典 key对应显示名称 value对应url
//eg. @{@"超清 720p":@"http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8",@"高清 480p":@"http://ivi.bupt.edu.cn/hls/cctv1.m3u8"}
@property (nonatomic, strong) NSDictionary *mediasourceDefinitionDict;

@property (nonatomic, weak) id<YZMoviePlayerControllerDelegate> delegate;
//控制层
@property (nonatomic, strong) YZMoviePlayerControls *controls;
//封面层
@property (nonatomic, strong) YZMoivePlayerCoverView *coverView;
//重播层
@property (nonatomic, strong) YZMoivePlayerReplayView *replayView;

@property (nonatomic, assign) YZMoviePlayerControlsStyle controlsStyle;
//由SDK判断的直播标识
@property (nonatomic, assign) BOOL isLive;
//接受到的是否是直播的标识
@property (nonatomic, assign) BOOL isReceiveLive;

@property (nonatomic, assign) BOOL isMultiPlay;
//是否自动播放
@property (nonatomic, assign) BOOL isAutoPlay;
//竖屏大窗时的父视图 用于横竖屏切换
@property (nonatomic, weak) X1PlayerView *fatherView;

//是否真的点击了全屏按钮,因为触发全屏可能是因为旋转屏幕
@property (nonatomic, assign) BOOL isRealFullScreenBtnPress;

//播放器SDK
@property (nonatomic, strong) X1Player *playerSDK;
//播放器状态
@property (nonatomic, assign) X1PlayerState playerMediaState;

@property (nonatomic, strong) GLKView *glkView;
//是否是全屏
@property (nonatomic, readwrite) BOOL movieFullscreen;
//是否是倒计时视图
@property (nonatomic, assign) BOOL isCountdownView;
//是否需要竖屏情况下展示返回按钮
@property (nonatomic, assign) BOOL isNeedShowBackBtn;
//是否完成的标识
@property (nonatomic, assign) BOOL isCompletion;

@property (nonatomic, assign) BOOL isHitBackBtn;

//封面图片
@property (nonatomic, strong) UIImage *coverimage;


/**
 初始化方法

 @param frame 坐标
 @param style 控制层风格
 @param mediasourceDefinitionDict 视频清晰度字典

 */
- (id)initWithFrame:(CGRect)frame andStyle:(YZMoviePlayerControlsStyle)style mediasourceDefinitionDict:(NSDictionary *)mediasourceDefinitionDict hostObject:(X1PlayerView *)hostObject;
- (void)setFrame:(CGRect)frame;
-(void)setMovieCoverImage:(UIImage*)image;

//点击了返回按钮
- (void)clickBackBtn;
//点击了全屏按钮
- (void)clickFullScreenBtn;
//点击了播放暂停按钮
- (void)clickPlayPauseBtn;
//点击了悬浮小窗窗体
-(void)clickFloatView;
//点击了悬浮小窗关闭按钮
-(void)clickCloseFloatViewBtn;

- (void)changeTitle:(NSString*)title;

//设备旋转时调用
-(void)rorateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

//全屏按钮点击时调用
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;

// 强制屏幕转屏
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation;

//全屏按钮点击时 && 设备旋转时  都会调用的方法
- (void)setFullscreen:(BOOL)fullscreen orientation:(UIInterfaceOrientation)orientation  animated:(BOOL)animated;


-(void)resetNoNetViewFrame:(CGRect)frame;

-(void)resetLodingViewFrame:(CGRect)frame;
//设置遮罩层颜色
-(void)setBarGradientColor:(UIColor *)color;


/*********************** 播放控制模块  ************************/
//播放
- (void)play;
//暂停
- (void)pause;
//停止，不再缓冲
- (void)stop;
//继续播放
- (void)resume;
//播放出错进行的重连(刷新，点播调用会从断点继续播)
-(void)retryPlay;
//直播重连操作(相当于刷新，点播调用会从头开始播)
- (void)restart;
//定点播放
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime;
//获得当前播放状态
- (X1PlayerState)getPlaybackState;
//设置当前播放状态
- (void)setPlayerMediaState:(X1PlayerState)state;
//关键代码 设置播放地址
- (void)setContentURL:(NSString *)contentURL;
//获取可播放时长
- (NSTimeInterval)playableDuration;
//获取当前时长
- (NSTimeInterval)currentPlaybackTime;





@end
