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
@property (nonatomic, strong) YZMoviePlayerCountdownView *countdownView;

//父视图(大窗状态时的父视图 由悬浮小窗切换到大窗时 由横屏切换到竖屏时使用)
@property (nonatomic, weak) UIView *fatherView;

@end

@implementation X1PlayerView

#pragma mark  -- LifeCycle
//初始化方法
- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        self.originalFrame = frame;
        
        [self setupConfig];

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
    
    
    //还原自动黑屏
    [UIApplication sharedApplication].idleTimerDisabled=NO;
    
}

-(void)dealloc{
    
    [self removeNotifications];
    
    [self viewDestroy];
    

}


//布局子视图
-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    if (self.countdownView) {
    
        [self bringSubviewToFront:self.countdownView];
    }
    
}

#pragma mark -- Public Method
//普通播放视频 无清晰度切换
-(void)playWithUrl:(NSString *)url playerTitle:(NSString *)title coverImage:(UIImage *)coverImage autoPlay:(BOOL)autoplay style:(YZMoviePlayerControlsStyle)style{
    
 
    [self playWithUrl:url definitionUrlDict:nil playerTitle:title coverImage:coverImage autoPlay:autoplay style:style];
    
}
// !!!: 播放视频核心方法
-(void)playWithUrl:(NSString *)url definitionUrlDict:(NSDictionary *)definitionUrlDict playerTitle:(NSString *)title coverImage:(UIImage *)coverImage autoPlay:(BOOL)autoplay style:(YZMoviePlayerControlsStyle)style{
    //当前播放视频地址与上一个地址比较
    __block BOOL isSameUrl = NO;
    
    if ([GlobalPlayerView.mediasource isEqual:url]) {
        isSameUrl = YES;
    }else{
        [definitionUrlDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isEqual:url]) {
                *stop = YES;
                isSameUrl = YES;
            }
        }];
    }

    //网址相同并且小窗存在情况下过来的,需要继续播放
    if (GlobalPlayerView && isSameUrl) {
        
        self.moviePlayer = GlobalPlayerView.moviePlayer;
        
        self.moviePlayer.delegate = self;
        self.moviePlayer.fatherView = self;
        self.moviePlayer.controlsStyle = style;
        
        [self.moviePlayer setFrame:CGRectMake(0, 0, _originalFrame.size.width, _originalFrame.size.height)];
        
        [self addSubview:self.moviePlayer.view];
        
        //重设控制层UI状态的通知
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerMediaStateChangedNotification object:nil];
        
        [GlobalPlayerView viewDestroy];
        
    }else{ //初始化一个新的开始播放
        
        [GlobalPlayerView viewDestroy];
        
        if (self.moviePlayer) {
            [self.moviePlayer stop];
            [self.moviePlayer.view removeFromSuperview];
            self.moviePlayer = nil;
        }
        
        
        [self setUpMoviePlayWithStyle:style mediasourceDefinitionDict:definitionUrlDict];
        
        self.moviePlayer.isAutoPlay = autoplay; //视频是否自动播放
        self.moviePlayer.coverimage = coverImage;
        [self.moviePlayer changeTitle:title];
        
        //播放视频关键代码
        [self.moviePlayer setContentURL:url];
        
    }
    
    //通用信息填充
    //不自动黑屏
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    self.style = style;
    self.playerTitle = title;
    self.mediasource = url;
    self.coverimage = coverImage;
    self.mediasource = url;
    self.mediasourceDefinitionDict = definitionUrlDict;
    
}


//展示倒计时视图
-(void)showCountdownViewWithIsLive:(BOOL)isLive startTime:(NSTimeInterval)startTime{
    
    self.isReceiveLive = isLive;//是否是直播
    self.startTimeInterval = startTime;
    //设置添加视图
    [self setupBeforeStartView];
    
}

//显示悬浮小窗
-(void)showFloatViewWithFrame:(CGRect)frame showCloseBtn:(BOOL)showCloseBtn{
    
    //展示悬浮小窗
    //判断 self.superview 是为了防止连续调用两次showFloatViewWithFrame 导致父视图缺失
    if (!self.moviePlayer.isCountdownView && [self.moviePlayer getPlaybackState] == PS_PLAYING  && self.superview){
        // 16 : 9 的比例
        
        self.originalFrame = frame;
        self.smallViewFrame = frame;
        
        [self.moviePlayer setFrame:frame];
        
        self.fatherView = self.superview;

        
        [[UIApplication sharedApplication].keyWindow addSubview:self.moviePlayer.view];
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
//由小窗切换为大窗口(适用于点击小窗恢复大窗 往下滑当前tableView直到视频播放窗口不可见时调用)
-(void)showOriginView{
    
    self.moviePlayer.controls.style = YZMoviePlayerControlsStyleDefault;
    [self setFrame:_originalFrame];
    [self addSubview:self.moviePlayer.view];
    
    [_fatherView addSubview:self];

    GlobalPlayerView = nil;
    
}

//屏幕旋转时调用
-(void)rorateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation animated:(BOOL)animated{
    
    //播放器旋转
    [self.moviePlayer rorateToOrientation:interfaceOrientation animated:animated];
}


#pragma mark -- Internal Method

-(void)setupConfig{
    
    //销毁计时器
    [self invalidCountDownTimer];
    
    //网络监测器
    self.networkMonitor =[YZReachability reachabilityForInternetConnection];
    [self.networkMonitor startNotifier];
    
}
//设置播放控制器
-(void)setUpMoviePlayWithStyle:(YZMoviePlayerControlsStyle)style mediasourceDefinitionDict:(NSDictionary *)mediasourceDefinitionDict;
{
    
    self.moviePlayer =[[YZMoviePlayerController alloc] initWithFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height) andStyle:style mediasourceDefinitionDict:mediasourceDefinitionDict hostObject:self];
    
    self.moviePlayer.view.alpha = 1.0f;
    self.moviePlayer.delegate = self;
    [self addSubview:self.moviePlayer.view];
    
    
    [self.moviePlayer changeTitle:self.playerTitle];
    
    
    [self.moviePlayer setFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height)];
    
}

// 设置未开播视图
-(void)setupBeforeStartView{
    
    if (self.isReceiveLive && (self.startTimeInterval -[[NSDate date] timeIntervalSince1970]) > 0) {
        //未开播
        
        [self.countdownView removeFromSuperview];
        self.countdownView = nil;
        [self initCountdownView];
        
        self.moviePlayer.isCountdownView = YES;
        [self.moviePlayer stop];
        
        
    }else if(self.isReceiveLive && (self.startTimeInterval -[[NSDate date] timeIntervalSince1970]) <= 0){ //直播中
        [self.countdownView removeFromSuperview];
        self.countdownView = nil;
        self.moviePlayer.isCountdownView = NO;
        
    }else{//录播
        [self.countdownView removeFromSuperview];
        self.countdownView = nil;
        self.moviePlayer.isCountdownView = NO;
        
    }
}

//初始化没开播视图
-(void)initCountdownView{
    
    self.countdownView = [[YZMoviePlayerCountdownView alloc] initWithStartTimeInterval:self.startTimeInterval];
    self.countdownView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:self.countdownView];
    
    
}

//销毁倒计时计时器
-(void)invalidCountDownTimer{
    if (self.countdownView.countDownTimer) {
        [self.countdownView.countDownTimer invalidate];
        self.countdownView.countDownTimer = nil;
    }
}


#pragma mark  --  Notification
//注册通知,设置通知回调
- (void)registerNotification
{
    /*********************** 注册播放器相关的通知 *********************/
    //播放器将要进入全屏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillEnterFullscreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    //播放器将要退出全屏通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullscreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];
    //视频播放完成回调
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieplayerFinish:) name:YZMoviePlayerOnCompletionNotification object:nil];
    
    // UIApplicationDidBecomeActiveNotification应用程序进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeroundNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    // UIApplicationWillResignActiveNotification应用程序进入后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    
    //未开播倒计时走完通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(countdownTimeout:) name:YZCountdownTimeoutNotification object:nil];
    
}
//移除所有通知
- (void)removeNotifications
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
//进入全屏通知
-(void)moviePlayerWillEnterFullscreen:(NSNotification *)sender{
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnWillEnterFullScreen:)]) {
        [self.delegate x1PlayerViewOnWillEnterFullScreen:self];
    }
}
//退出全屏通知
-(void)moviePlayerWillExitFullscreen:(NSNotification *)sender{
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnWillExitFullScreen:)]) {
        [self.delegate x1PlayerViewOnWillExitFullScreen:self];
    }
    
}
//视频播放完毕的回调
-(void)movieplayerFinish:(NSNotification *)sender{
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnPlayFinish:)]) {
        [self.delegate x1PlayerViewOnPlayFinish:self];
    }
}

//程序已经进入前台
- (void)appDidEnterForeroundNotification:(NSNotification *)note {
    
    if (self.isSwitchResumePlay) {
        [self.moviePlayer play];
        self.isSwitchResumePlay = NO;
    }
}

//程序已经进入后台
- (void)appDidEnterBackgroundNotification:(NSNotification *)note {
    
    if (self.moviePlayer.getPlaybackState == PS_PLAYING)
    {
        self.isSwitchResumePlay = YES;
        [self.moviePlayer pause];
    }
}

//倒计时时间结束回调
-(void)countdownTimeout:(NSNotification *)sender{
    [self.countdownView.countDownTimer invalidate];
    self.countdownView.countDownTimer = nil;
    
    [self.countdownView removeFromSuperview];
    self.countdownView = nil;
    
    [self.moviePlayer play];
    self.moviePlayer.controls.style = YZMoviePlayerControlsStyleLivePortrait;
    
}


#pragma mark -- Mediaplayer Control
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



#pragma mark - YZMoviePlayerControllerDelegate

- (void)yzMoviePlayerControllerMovieTimedOut {
    
    //FIXME:网络连接失败
//    if (![QNAlertUtil connectedToNetwork]) {
//        [QNAlertUtil showNoneNetWorkAlert];
//    }
}

//悬浮小窗被点击
-(void)yzMoviePlayerControllerOnClickFloatView{
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickFloatView:)]) {
        [self.delegate x1PlayerViewOnClickFloatView:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerViewOnClickFloatViewNotification object:self];
    
}
//悬浮小窗叉号按钮被点击
-(void)yzMoviePlayerControllerOnClickCloseFloatViewBtn{
    
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickCloseFloatViewBtn:)]) {
        [self.delegate x1PlayerViewOnClickCloseFloatViewBtn:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerVuewOnClickCloseFloatViewBtnNotification object:self];
    
    [GlobalPlayerView viewDestroy];
    
    
}
//视频返回按钮点击的回调
-(void)yzMoviePlayerControllerOnClickBackBtn{
    
    if ([self.delegate respondsToSelector:@selector(x1PlayerViewOnClickBackBtn:)]) {
        [self.delegate x1PlayerViewOnClickBackBtn:self];
    }
    
}
//切换横屏
- (void)yzMoviePlayerControllerMoviePlayerWillEnterFullScreen {
    NSLog(@"X1PlayerView 将要进入了全屏");
    self.fatherView = self.superview;

    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [self setFrame:CGRectMake(0, 0, MAX(window.bounds.size.height, window.bounds.size.width), MIN(window.bounds.size.height, window.bounds.size.width))];
    
    [window addSubview:self];
    
    if (YZBrightnessViewShared) {
        [window bringSubviewToFront:YZBrightnessViewShared];
    }
    
    
}
//切换竖屏
-(void)yzMoviePlayerControllerMoviePlayerWillExitFullScreen{
    NSLog(@"X1PlayerView 将要退出了全屏");
    //异常处理
    if (![self.subviews containsObject:self.moviePlayer.view]){
        [self addSubview:self.moviePlayer.view];
    }
    [self setFrame:self.originalFrame];
    [self.moviePlayer setFrame:CGRectMake(0, 0, self.originalFrame.size.width, self.originalFrame.size.height)];
    
    [self.fatherView addSubview:self];

}



#pragma mark --  Setter && Getter
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
    
    self.moviePlayer.coverimage = self.coverimage;

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
