//
//  X1PlayerView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "X1PlayerView.h"
#import "YZMoviePlayerControls.h"
#import "X1Player.h"
#import "YZColorUtil.h"
#import "YZMoviePlayerCountdownView.h"
#import "YZMoivePlayerBrightnessView.h"


#define  YZVIDEOHEIGHT      [[UIScreen mainScreen] bounds].size.width*9/16
#define  YZVIDEOHEIGHT_PAD  535.f


//点击小窗的通知
NSString * const X1PlayerViewOnClickFloatViewNotification = @"X1PlayerViewOnClickFloatViewNotification";
//点击小窗关闭按钮的通知
NSString * const X1PlayerVuewOnClickCloseFloatViewBtnNotification = @"X1PlayerVuewOnClickCloseFloatViewBtnNotification";

//globalPlayerView在小窗的情况下有值
static X1PlayerView  *GlobalPlayerView;

@interface  X1PlayerView()<YZMoviePlayerControllerDelegate>
//初始化的frame
@property (nonatomic, assign) CGRect originalFrame;
//小窗的frame
@property (nonatomic, assign) CGRect smallViewFrame;
//未开播倒计时视图
@property (nonatomic, strong) YZMoviePlayerCountdownView *noStartView;
//父视图
@property (nonatomic, weak) UIView *fatherView;

@end

@implementation X1PlayerView

#pragma mark  -- lifecycle
//初始化方法
- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        self.originalFrame = frame;
        //销毁计时器
        [self invalidCountDownTimer];
        //注册通知
        [self registerNotification];
        
    }
    return self;
}

//视图销毁
-(void)viewDestroy{
    
    [self.moviePlayer stop];
    [self removeNotifications];
    [self invalidCountDownTimer];
    
    [self.moviePlayer.view removeFromSuperview];
    [self removeFromSuperview];
    
    GlobalPlayerView = nil;
    
    //还原自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled=NO;
    
}

-(void)dealloc{
    
    [self removeNotifications];
    
}

//布局子视图
-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    
    self.noStartView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self bringSubviewToFront:self.noStartView];
    
}


#pragma mark -- public method
// !!!: 播放视频
-(void)playWithUrl:(NSString *)url playerTitle:(NSString *)title coverImage:(UIImage *)coverImage autoPlay:(BOOL)autoplay style:(YZMoviePlayerControlsStyle)style{
    
    //不自动锁屏
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    
    self.style = style;
    self.playerTitle = title;
  
    //播放视频
    self.mediasource = url;
    self.coverimage = coverImage;
    
    //网址相同并且小窗存在情况下过来的,需要继续播放
    if (GlobalPlayerView && [GlobalPlayerView.moviePlayer.lastPlayUrl isEqual:url]) {
        
        self.moviePlayer = GlobalPlayerView.moviePlayer;
        
        self.moviePlayer.delegate = self;
        self.moviePlayer.fatherView = self;
        
        
        [self.moviePlayer setFrame:CGRectMake(0, 0, _originalFrame.size.width, _originalFrame.size.height)];
        
        [self addSubview:self.moviePlayer.view];
        
        self.moviePlayer.controlsStyle = style;
        
        //重设控制层UI状态
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerMediaStateChangedNotification object:nil];
        
        [GlobalPlayerView removeNotifications];
        [GlobalPlayerView invalidCountDownTimer];
        GlobalPlayerView = nil;
        
        
    }else{ //初始化一个新的开始播放
        [GlobalPlayerView viewDestroy];
        
        if (self.moviePlayer) {
            [self.moviePlayer stop];
            [self.moviePlayer.view removeFromSuperview];
            self.moviePlayer = nil;
        }
        
        
        [self setUpMoviePlayWithStyle:style];
        
        self.moviePlayer.isAutoPlay = autoplay; //视频是否自动播放
        self.moviePlayer.coverimage = self.coverimage;
        self.moviePlayer.lastPlayUrl = url;
        [self.moviePlayer changeTitle:title];
        
       
        
        //播放视频关键代码
        [self.moviePlayer setContentURL:[NSURL URLWithString:url]];
    }
}

//展示未开播视图
-(void)showNoStartViewWithIsLive:(BOOL)isLive startTime:(NSTimeInterval)startTime{
    
    self.isReceiveLive = isLive;//是否是直播
    self.startTimeInterval = startTime;
    //设置添加视图
    [self setupBeforeStartView];
    
}

//显示悬浮小窗
-(void)showFloatViewWithFrame:(CGRect)frame showCloseBtn:(BOOL)showCloseBtn{
    
    //判断 self.superview 是为了防止连续调用两次showFloatViewWithFrame 导致父视图缺失
    if (!self.moviePlayer.isNoStartView && self.superview && [self.moviePlayer getPlaybackState] == PS_PLAYING){
        // 16 : 9 的比例
        
        self.originalFrame = frame;
        self.smallViewFrame = frame;
        
        [self.moviePlayer setFrame:frame];
        
        self.fatherView = self.superview;
        
        [[UIApplication sharedApplication].delegate.window addSubview:self.moviePlayer.view];
        GlobalPlayerView  = self;  //绑定全局变量
        NSLog(@"========%@",GlobalPlayerView);
        [self removeFromSuperview];
        self.moviePlayer.controls.style = YZMoviePlayerControlsStyleFloatView; //设置小窗悬浮模式
        
    }else{
        
        [self viewDestroy];
        
    }
    
    if (showCloseBtn) {
        self.moviePlayer.controls.floatView.floatViewCloseBtn.alpha = 1;
    }else{
        
        self.moviePlayer.controls.floatView.floatViewCloseBtn.alpha = 0;
        
    }
    
    
    
}

// 滑动scrollView显示大窗(上滑当前tableView直到视频播放窗口可见时调用)
-(void)showOriginalViewWhileSlideUpPage{
    
    self.moviePlayer.controls.style = YZMoviePlayerControlsStyleDefault;
    [self setFrame:_originalFrame];
    [self addSubview:self.moviePlayer.view];
    [_fatherView addSubview:self];
    
    GlobalPlayerView = nil;
    
}

// 屏幕旋转时调用
-(void)rorateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated{
    
    //播放器旋转
    [self.moviePlayer rorateToOrientation:interfaceOrientation animated:animated];
}

#pragma mark -- mediaplayer control
//播放
- (void)play{
    
    [self.moviePlayer play];
}
//暂停
- (void)pause{
    
    [self.moviePlayer pause];
}
//停止，不再缓冲
- (void)stop{
    
    [self.moviePlayer stop];
}
//继续播放
-(void)resume{
    
    [self.moviePlayer resume];
}

//播放出错进行的重连(刷新，点播调用会从断点继续播)
-(void)retryPlay{
    
    [self.moviePlayer retryPlay];
}
//直播重连操作(相当于刷新，点播调用会从头开始播)
- (void)restart{
    
    [self.moviePlayer restart];
}
//定点播放
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime{
    
    [self.moviePlayer setCurrentPlaybackTime:currentPlaybackTime];
}
//获得当前播放状态
- (X1PlayerState)getPlaybackState{
    
    return  [self.moviePlayer getPlaybackState];
}

// 获取可播放时长
- (NSTimeInterval)playableDuration{
    
    return  [self.moviePlayer playableDuration];
}
// 获取当前时长
- (NSTimeInterval)currentPlaybackTime{
    
    return [self.moviePlayer currentPlaybackTime];
}


#pragma mark -- internal method
// 设置未开播视图
-(void)setupBeforeStartView{
    
    if (self.isReceiveLive && (self.startTimeInterval -[[NSDate date] timeIntervalSince1970]) > 0) {
        //未开播
        
        [self.noStartView removeFromSuperview];
        self.noStartView = nil;
        [self initNoStartView];
        
        self.moviePlayer.isNoStartView = YES;
        [self.moviePlayer stop];

        
    }else if(self.isReceiveLive && (self.startTimeInterval -[[NSDate date] timeIntervalSince1970]) <= 0){ //直播中
        [self.noStartView removeFromSuperview];
        self.noStartView = nil;
        self.moviePlayer.isNoStartView = NO;
        
    }else{//录播
        [self.noStartView removeFromSuperview];
        self.noStartView = nil;
        self.moviePlayer.isNoStartView = NO;
        
    }
}
//设置播放控制器
-(void)setUpMoviePlayWithStyle:(YZMoviePlayerControlsStyle)style
{
    
    self.moviePlayer =[[YZMoviePlayerController alloc] initWithFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height) andStyle:style];
    
    self.moviePlayer.view.alpha = 1.0f;
    self.moviePlayer.delegate = self;
    self.moviePlayer.fatherView = self;
    [self addSubview:self.moviePlayer.view];
    NSLog(@"QNX1playerView setUpMoviePlay %@",self.moviePlayer.view);
    
    
    [self.moviePlayer changeTitle:self.playerTitle];
    
    
    [self.moviePlayer setFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height)];
    
    _coverImageView = self.moviePlayer.coverView.coverImageView;

    
}
//初始化没开播视图
-(void)initNoStartView{
    
    self.noStartView = [[YZMoviePlayerCountdownView alloc] initWithStartTimeInterval:self.startTimeInterval];
    [self addSubview:self.noStartView];
    
}

//销毁倒计时计时器
-(void)invalidCountDownTimer{
    if (self.noStartView.countDownTimer) {
        [self.noStartView.countDownTimer invalidate];
        self.noStartView.countDownTimer = nil;
    }
}


#pragma mark  --  notification
//注册通知,设置通知回调
- (void)registerNotification
{
    NSLog(@"QNX1PlayerView registerNotification");
    // 注册播放器相关的通知
    //播放器将要进入全屏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qnMoviePlayerWillEnterFullscreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    //播放器将要退出全屏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qnMoviePlayerWillExitFullscreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];
    //视频播放完成回调
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qnMovieplayerFinish:) name:YZMoviePlayerOnCompletionNotification object:nil];
    
    // UIApplicationDidBecomeActiveNotification应用程序进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    // UIApplicationWillResignActiveNotification应用程序进入后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
    //未开播倒计时走完通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(qnCountdownTimeout:) name:QNCountdownTimeoutNotification object:nil];
    
}
//移除所有通知
- (void)removeNotifications
{
    NSLog(@"QNX1PlayerView removeNotifications");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//进入全屏通知
-(void)qnMoviePlayerWillEnterFullscreen:(NSNotification *)sender{
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnWillEnterFullScreen:)]) {
        [self.delegate x1PlayerViewOnWillEnterFullScreen:self];
    }
}
//退出全屏通知
-(void)qnMoviePlayerWillExitFullscreen:(NSNotification *)sender{
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnWillExitFullScreen:)]) {
        [self.delegate x1PlayerViewOnWillExitFullScreen:self];
    }
    
}
//视频播放完毕的回调
-(void)qnMovieplayerFinish:(NSNotification *)sender{
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnPlayFinish:)]) {
        [self.delegate x1PlayerViewOnPlayFinish:self];
    }
}

//程序已经进入前台
- (void)appDidEnterForeroundNotification:(NSNotification *)note {
    
    if (self.isSwitchForegroundNeedResumePlay) {
        [self.moviePlayer play];
        self.isSwitchForegroundNeedResumePlay = NO;
    }
}

//程序已经进入后台
- (void)appDidEnterBackgroundNotification:(NSNotification *)note {
    
    if (self.moviePlayer.getPlaybackState == PS_PLAYING)
    {
        self.isSwitchForegroundNeedResumePlay = YES;
        [self.moviePlayer pause];
    }
}

//倒计时时间结束回调
-(void)qnCountdownTimeout:(NSNotification *)sender{
    [self.noStartView.countDownTimer invalidate];
    self.noStartView.countDownTimer = nil;
    
    [self.noStartView removeFromSuperview];
    self.noStartView = nil;
    
    [self.moviePlayer play];
    self.moviePlayer.controls.style = YZMoviePlayerControlsStyleLivePortrait;
    
}

#pragma mark - YZMoviePlayerControllerDelegate

- (void)qnMoviePlayerControllerMovieTimedOut {
    NSLog(@"QNX1PlayerView MOVIE TIMED OUT");
    
    //FIXME:网络连接失败
//    if (![QNAlertUtil connectedToNetwork]) {
//        [QNAlertUtil showNoneNetWorkAlert];
//    }
}

//悬浮小窗被点击
-(void)qnMoviePlayerControllerFloatViewPressed{
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickFloatView:)]) {
        [self.delegate x1PlayerViewOnClickFloatView:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerViewOnClickFloatViewNotification object:self];
    
}
//悬浮小窗叉号按钮被点击
-(void)qnMoviePlayerControllerCloseFloatViewBtnPressed{
    
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickCloseFloatViewBtn:)]) {
        [self.delegate x1PlayerViewOnClickCloseFloatViewBtn:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerVuewOnClickCloseFloatViewBtnNotification object:self];
    
    [GlobalPlayerView viewDestroy];
    
    
}
//视频返回按钮点击的回调
-(void)qnMoviePlayerControllerBackBtnPressed{
    NSLog(@"QNX1PlayerView backBtnPressed");
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickBackBtn:)]) {
        [self.delegate x1PlayerViewOnClickBackBtn:self];
    }
    
}
//切换横屏
- (void)qnMoviePlayerControllerMoviePlayerWillEnterFullScreen {
    NSLog(@"QNX1PlayerView 将要进入了全屏");
    
    self.fatherView = self.superview;
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [self setFrame:CGRectMake(0, 0, MAX(window.bounds.size.height, window.bounds.size.width), MIN(window.bounds.size.height, window.bounds.size.width))];
    
    [window addSubview:self];
    
    if (YZBrightnessViewShared) {
        [window bringSubviewToFront:YZBrightnessViewShared];
    }
    
    
}
//切换竖屏
-(void)qnMoviePlayerControllerMoviePlayerWillExitFullScreen{
    NSLog(@"QNX1PlayerView 将要退出了全屏");
    //异常处理
    if (![self.subviews containsObject:self.moviePlayer.view]){
        [self addSubview:self.moviePlayer.view];
    }
    [self setFrame:self.originalFrame];
    [self.moviePlayer setFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height)];
    
    [self.fatherView addSubview:self];
    
}



#pragma mark --  setter && getter
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    //为什么不放到layoutSubview里面 因为全屏的时候moviePlayer frame应该为 20,20,self.bounds.size.width, self.bounds.size.height
    [self.moviePlayer setFrame:CGRectMake(0, 0,self.bounds.size.width, self.bounds.size.height)];
}
-(void)setOriginalFrame:(CGRect)originalFrame{
    
    _originalFrame = originalFrame;
}

-(void)setCoverimage:(UIImage *)coverimage{
    
    _coverimage = coverimage;
}

-(void)setStyle:(YZMoviePlayerControlsStyle)style{
    _style = style;
    
    [self.moviePlayer.controls setStyle:style];
    
}

-(void)setIsNeedShowBackBtn:(BOOL)isNeedShowBackBtn{
    
    _isNeedShowBackBtn = isNeedShowBackBtn;
    
    self.moviePlayer.isNeedShowBackBtn = isNeedShowBackBtn;
    
}

-(void)setBarGradientColor:(UIColor *)color{
    
    [self.moviePlayer setBarGradientColor:color];
}



@end
