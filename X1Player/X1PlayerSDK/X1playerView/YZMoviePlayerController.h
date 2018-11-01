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
#import "YZMoviePlayerCoverView.h"
#import "YZMoviePlayerReplayView.h"

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

@class X1PlayerView,YZMutipleDefinitionModel;
@protocol YZMoviePlayerControllerDelegate <NSObject>
@optional
//播放完成
- (void)yzMoviePlayerControllerPlayComplete;
//缓冲超时
- (void)yzMoviePlayerControllerMovieTimedOut;
//点击锁屏按钮回调
- (void)yzMoviePlayerControllerOnClickLockBtn:(BOOL)isLocked;
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
//播放器视频清晰度数组
@property (nonatomic, strong) NSArray <YZMutipleDefinitionModel *>*mediasourceDefinitionArr;

@property (nonatomic, weak) id<YZMoviePlayerControllerDelegate> delegate;
//控制层
@property (nonatomic, strong) YZMoviePlayerControls *controls;
//封面层
@property (nonatomic, strong) YZMoviePlayerCoverView *coverView;
//重播层
@property (nonatomic, strong) YZMoviePlayerReplayView *replayView;
//控制层风格
@property (nonatomic, assign) YZMoviePlayerControlsStyle controlsStyle;
//由SDK判断的直播标识
@property (nonatomic, assign) BOOL isLive;
//是否锁屏
@property (nonatomic, assign) BOOL isLocked;

//外界传入的是否是直播的标识
@property (nonatomic, assign) BOOL isReceiveLive;
//是否自动播放
@property (nonatomic, assign) BOOL isAutoPlay;
//竖屏大窗时的父视图 用于横竖屏切换
@property (nonatomic, weak) X1PlayerView *fatherView;
//是否真的点击了全屏按钮,因为触发全屏旋转操作的可能是手机横置
@property (nonatomic, assign) BOOL isRealFullScreenBtnPress;
//播放器SDK
@property (nonatomic, strong) X1Player *playerSDK;
//播放器状态
@property (nonatomic, assign) X1PlayerState playerMediaState;
//保存上一次播放状态 (用于应用前后台切换)
@property (nonatomic, assign) X1PlayerState lastPlayerMediaState;

@property (nonatomic, strong) GLKView *glkView;
//是否是全屏
@property (nonatomic, readwrite) BOOL movieFullscreen;
//是否是倒计时视图
@property (nonatomic, assign) BOOL isCountdownView;
//是否需要竖屏情况下展示返回按钮
@property (nonatomic, assign) BOOL isNeedShowBackBtn;
//播放器播放完成的标识
@property (nonatomic, assign) BOOL isCompletion;

@property (nonatomic, assign) BOOL isHitBackBtn;
//封面图片
@property (nonatomic, strong) UIImage *coverimage;
//是否已经展示过 流量播放提醒 (如果展示过 autoPlay==YES的情况下 播放续集 不再次展示)
@property (nonatomic, assign) BOOL isShowedWWANView;


/**
 初始化方法

 @param frame 坐标
 @return 实例
 */
-(instancetype)initWithFrame:(CGRect)frame;

/**
 设置控制层

 @param style 控制层风格
 */
- (void)setupControlWithStyle:(YZMoviePlayerControlsStyle)style;


- (void)setFrame:(CGRect)frame;




-(void)setMovieCoverImage:(UIImage*)image;

- (void)changeTitle:(NSString*)title;

-(void)resetNoNetViewFrame:(CGRect)frame;

-(void)resetLodingViewFrame:(CGRect)frame;
//设置遮罩层颜色
-(void)setBarGradientColor:(UIColor *)color;
//展示重播视图
-(void)showReplayView;

/*********************** 设备旋转相关  ************************/
//设备旋转时调用
-(void)rorateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;
//全屏按钮点击时调用
- (void)setFullscreen:(BOOL)fullscreen animated:(BOOL)animated;
// 强制屏幕转屏
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation;
//全屏按钮点击时 && 设备旋转时  都会调用的核心方法
- (void)setFullscreen:(BOOL)fullscreen orientation:(UIInterfaceOrientation)orientation  animated:(BOOL)animated;

/*********************** 控件操作事件  ************************/
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

/*********************** 播放控制模块  ************************/
//播放
- (void)play;
//暂停
- (void)pause;
//停止，不再缓冲
- (void)stop;
//直播断点续播  录播继续播放
- (void)resume;
//播放出错进行的重连(刷新，点播调用会从断点继续播)
-(void)retryPlay;
//直播重连操作(相当于刷新，点播调用会从头开始播)
- (void)restart;
//定点播放
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime;
//释放资源
-(void)releasePlayer;

//设置当前播放状态
- (void)setPlayerMediaState:(X1PlayerState)state;
//关键代码 设置播放地址
- (void)setContentURL:(NSString *)contentURL;
//改变播放源
- (void)changeContentURL:(NSString *)contentURL;

//获取可播放时长
- (NSTimeInterval)playableDuration;
//获取当前时长
- (NSTimeInterval)currentPlaybackTime;



@end
