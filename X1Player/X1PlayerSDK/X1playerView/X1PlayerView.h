//
//  X1PlayerView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  最外层的view 包含播放器 倒计时层 和可能添加的弹幕层 业务逻辑层
//  Email : fyz333501@163.com
//  GitHub: https://github.com/diamondfive/X1Player
//  如有问题或建议请给我发Email, 或在该项目的GitHub主页lssues我, 谢谢:)

#import <UIKit/UIKit.h>
#import "YZMoviePlayerController.h"
#import "YZReachability.h"
#import "YZMutipleDefinitionModel.h"

#define X1BUNDLE_NAME   @"X1Player.bundle"
#define X1BUNDLE_PATH   [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:X1BUNDLE_NAME]
#define X1BUNDLE_Image(imageName)   [X1BUNDLE_PATH stringByAppendingPathComponent:imageName]

#define  YZColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


//点击小窗的通知
extern NSString * const X1PlayerViewOnClickFloatViewNotification;
//点击小窗关闭按钮的通知
extern NSString * const X1PlayerVuewOnClickCloseFloatViewBtnNotification;

@class X1PlayerView;
@protocol X1PlayerViewDelegate <NSObject>
@optional
//将要进入全屏的回调
-(void)x1PlayerViewOnWillEnterFullScreen:(X1PlayerView *)x1PlayerView;
//将要退出全屏的回调
-(void)x1PlayerViewOnWillExitFullScreen:(X1PlayerView *)x1PlayerView;
//点击小窗的回调
-(void)x1PlayerViewOnClickFloatView:(X1PlayerView *)x1PlayerView;
//点击小窗关闭按钮的回调
-(void)x1PlayerViewOnClickCloseFloatViewBtn:(X1PlayerView *)x1PlayerView;
//点击竖屏返回按钮的回调
-(void)x1PlayerViewOnClickBackBtn:(X1PlayerView *)x1PlayerView;
//播放完成回调
-(void)x1PlayerViewOnPlayComplete:(X1PlayerView *)x1PlayerView;
//超时回调
-(void)x1PlayerViewOnPlayTimeout:(X1PlayerView *)x1PlayerView;
//点击锁屏按钮回调
-(void)x1PlayerViewOnClickLockBtn:(BOOL)isLocked;


@end

@interface X1PlayerView : UIView
//播放器数据源url
@property (nonatomic, strong) NSString *mediasource;
//播放器显示标题
@property (nonatomic, strong) NSString *playerTitle;
//播放器封面图片
@property (nonatomic, strong) UIImage *coverimage;
//视频播放器层
@property (nonatomic,strong) YZMoviePlayerController *moviePlayer;

@property (nonatomic, weak) id<X1PlayerViewDelegate> delegate;
//播放风格
@property (nonatomic, assign) YZMoviePlayerControlsStyle style;
//是否锁屏
@property (nonatomic, assign, readonly) BOOL isLocked;
//app后台切换到前台需不需要继续播放 默认YES
@property (nonatomic, assign) BOOL isSwitchResumePlay;
//播放器竖屏状态下是否需要显示返回按钮
@property (nonatomic, assign) BOOL isNeedShowBackBtn;
//网络监听器
@property (nonatomic, strong) YZReachability *networkMonitor;
//autoPlay == YES 时流量环境是否展示流量播放提醒界面,默认YES
@property (nonatomic, assign) BOOL isShowWWANViewInAutoPlay;
//网络环境变化为流量环境时是否展示流量播放提醒界面 默认YES
@property (nonatomic, assign) BOOL isShowWWANViewInNetworkChange;

/**********************  简单业务逻辑场景:直播预告倒计时 ****************************/
//是否是直播(外界传入的标识,用于SDK解析视频源成功前的逻辑判断)
@property (nonatomic, assign) BOOL isReceiveLive;
//开播时间戳(用于直播视频未开播前遮罩的逻辑判断,简单加入的业务逻辑场景)
@property (nonatomic, assign) NSTimeInterval startTimeInterval;


/**
 初始化方法
 @param frame 控件frame

 */
- (instancetype)initWithFrame:(CGRect)frame;


/**
  播放方法
 @param url 视频源的url
 @param title 视频标题
 @param coverImage 封面图片 也可通过coverImageView/coverImage设置图片
 @param autoplay 是否自动播放
 @param style  参考X1PlayerViewStyle
 */
-(void)playWithUrl:(NSString *)url playerTitle:(NSString *)title coverImage:(UIImage *)coverImage autoPlay:(BOOL)autoplay style:(YZMoviePlayerControlsStyle)style;

/**
  播放方法二 支持清晰度切换

 @param url 优先播放清晰度的url url需要存在于视频清晰度字典中
 @param definitionUrlArr 视频清晰度数组
 @param title 视频标题
 @param coverImage 封面图片 也可通过coverImageView/coverImage设置图片
 @param autoplay 是否自动播放
 @param style  参考X1PlayerViewStyle
 */
-(void)playWithUrl:(NSString *)url definitionUrlArr:(NSArray *)definitionUrlArr playerTitle:(NSString *)title coverImage:(UIImage *)coverImage autoPlay:(BOOL)autoplay style:(YZMoviePlayerControlsStyle)style;


/**
 手动调用销毁视频控件（eg. 离开视频播放页面时 全局悬浮窗点击叉号时调用）
 */
-(void)viewDestroy;


/**
 显示悬浮小窗（返回上级页面或者往上滑当前tableView直到视频播放窗口不可见时调用）
 
 @param frame 小窗坐标
 @param showCloseBtn 是否展示小窗关闭按钮
 */
-(void)showFloatViewWithFrame:(CGRect)frame showCloseBtn:(BOOL)showCloseBtn;


/**
  由小窗切换为大窗口(适用于 往下滑当前tableView直到视频播放窗口可见时调用 或者在这种场景下的小窗点击小窗叉号)
 
  warning: 错误调用会导致UI异常
  eg. 返回上一级页面的悬浮小窗不能调用此方法 因为此时再次进入播放界面 播放控件的父视图为不同对象
  此时需要在 x1PlayerViewOnClickFloatView 的回调中 或者X1PlayerViewOnClickFloatViewNotification 再次调用 playWithUrl 播放方法
 

 */
-(void)showOriginView;


//设备横竖屏切换的时候调用,可以让播放控件适应设备全屏 （为什么不封装在SDK内部，因为设备旋转之后播放界面不一定要变为全屏，比如 淘宝的黑色背景小窗 腾讯新闻的竖屏全屏大窗 都不是由设备旋转触发）
-(void)rorateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated;

/**
 展示直播开播前倒计时视图(简单业务逻辑场景)

 @param isLive 是否是直播
 @param startTime 开播时间距离1970年的时间戳 秒
 */
-(void)showCountdownViewWithIsLive:(BOOL)isLive startTime:(NSTimeInterval)startTime;


/************************** 个性化定制 *********************************/

//设置播放器标题
-(void)setPlayerTitle:(NSString *)playerTitle;
//设置封面图片
-(void)setCoverimage:(UIImage *)coverimage;
//设置控制层渐变遮罩颜色
-(void)setBarGradientColor:(UIColor *)color;
//展示重播视图
-(void)showReplayView;



/************************** 播放控制模块 *********************************/
//直播重连 录播继续播放
- (void)play;
//暂停
- (void)pause;
//停止，不再缓冲
- (void)stop;
//直播断点续播 录播继续播放
-(void)resume;
//播放出错进行的重连(刷新，点播调用会从断点继续播)
-(void)retryPlay;
//直播重连操作(相当于刷新，点播调用会从头开始播)
- (void)restart;
//定点播放
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime;
//获得当前播放状态
- (X1PlayerState)getPlaybackState;
//获取可播放时长
- (NSTimeInterval)playableDuration;
//获取当前时长
- (NSTimeInterval)currentPlaybackTime;






@end
