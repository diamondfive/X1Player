//
//  X1PlayerView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  最外层的view 包含播放器 倒计时层 和可能添加的弹幕层 业务逻辑层

#import <UIKit/UIKit.h>
#import "YZMoviePlayerController.h"

#define X1BUNDLE_NAME   @"X1Player.bundle"
#define X1BUNDLE_PATH   [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:X1BUNDLE_NAME]
#define X1BUNDLE_Image(imageName)   [X1BUNDLE_PATH stringByAppendingPathComponent:imageName]

#define  YZColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//点击小窗的通知
extern NSString * const X1PlayerViewOnClickFloatViewNotification;
//点击小窗关闭按钮的通知
extern NSString * const X1PlayerVuewOnClickCloseFloatViewBtnNotification;

@class X1PlayerView;
@protocol X1PlayerViewDelegate <NSObject,UITableViewDelegate>
@optional
//将要进入全屏
-(void)x1PlayerViewOnWillEnterFullScreen:(X1PlayerView *)x1PlayerView;
//将要退出全屏
-(void)x1PlayerViewOnWillExitFullScreen:(X1PlayerView *)x1PlayerView;
//点击小窗的回调
-(void)x1PlayerViewOnClickFloatView:(X1PlayerView *)x1PlayerView;
//点击小窗关闭按钮的回调
-(void)x1PlayerViewOnClickCloseFloatViewBtn:(X1PlayerView *)x1PlayerView;
//点击竖屏返回按钮的回调
-(void)x1PlayerViewOnClickBackBtn:(X1PlayerView *)x1PlayerView;
//播放完成回调
-(void)x1PlayerViewOnPlayFinish:(X1PlayerView *)x1PlayerView;

@end

@interface X1PlayerView : UIView

//视频数据源url
@property (nonatomic, strong) NSString *mediasource;
//视频数据源数组 通常是统一视频包含不同清晰度
@property (nonatomic, strong) NSArray *mediasourceArr;
//封面图片
@property (nonatomic, strong) UIImage *coverimage;
//封面图片所在控件 暴露用于sdwebimage调用
@property (nonatomic, strong, readonly) UIImageView *coverImageView;
//视频播放器
@property (nonatomic,strong) YZMoviePlayerController *moviePlayer;

@property (nonatomic, weak) id<X1PlayerViewDelegate> delegate;
//视频显示标题
@property (nonatomic, strong) NSString *playerTitle;
//是否是直播(外界传入的标识,用于SDK解析视频源成功前的逻辑判断)
@property (nonatomic, assign) BOOL isReceiveLive;
//开播时间戳(用于直播视频未开播前遮罩的逻辑判断)
@property (nonatomic, assign) NSTimeInterval startTimeInterval;
//播放风格
@property (nonatomic, assign) YZMoviePlayerControlsStyle style;
 //app后台切换到前台需不需要继续播放
@property (nonatomic, assign) BOOL isSwitchForegroundNeedResumePlay;
//竖屏状态下是否需要显示返回按钮
@property (nonatomic, assign) BOOL isNeedShowBackBtn;

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
 展示未开播视图

 @param isLive 是否是直播
 @param startTime 开播时间
 */
-(void)showNoStartViewWithIsLive:(BOOL)isLive startTime:(NSTimeInterval)startTime;
/**
 设置遮罩层颜色
 */
-(void)setBarGradientColor:(UIColor *)color;

//显示悬浮小窗 （返回或者上滑当前tableView直到视频播放窗口不可见时调用）
-(void)showFloatViewWithFrame:(CGRect)frame showCloseBtn:(BOOL)showCloseBtn;

//滑动scrollView显示大窗(上滑当前tableView直到视频播放窗口可见时调用)
-(void)showOriginalViewWhileSlideUpPage;

//手动调用销毁视频窗口（eg. 离开视频播放页面时调用）
-(void)viewDestroy;

//设备横竖屏切换的时候调用,可以让播放控件适应设备全屏 （为什么不封装在SDK内部，因为设备旋转之后播放界面不一定要变为全屏，比如 淘宝的黑色背景小窗 腾讯新闻的竖屏全屏大窗 都不是由设备旋转触发）
-(void)rorateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated;


/********************* 播放控制模块 *********************************/
//播放
- (void)play;
//暂停
- (void)pause;
//停止，不再缓冲
- (void)stop;
//继续播放
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
