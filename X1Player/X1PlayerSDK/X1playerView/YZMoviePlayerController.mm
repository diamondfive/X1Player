//
//  YZMoviePlayerController.m
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoviePlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import "X1PlayerView.h"
#import "YZMutipleDefinitionModel.h"


NSString * const YZMoviePlayerWillEnterFullscreenNotification = @"YZMoviePlayerWillEnterFullscreenNotification";
NSString * const YZMoviePlayerDidEnterFullscreenNotification = @"YZMoviePlayerDidEnterFullscreenNotification";
NSString * const YZMoviePlayerWillExitFullscreenNotification = @"YZMoviePlayerWillExitFullscreenNotification";
NSString * const YZMoviePlayerDidExitFullscreenNotification = @"YZMoviePlayerDidExitFullscreenNotification";
//播放完成回调
NSString * const YZMoviePlayerOnCompletionNotification = @"YZMoviePlayerOnCompletionNotification";
//播放状态变化通知
NSString * const YZMoviePlayerMediaStateChangedNotification = @"YZMoviePlayerMediaStateChangedNotification";
//播放地址改变通知
NSString * const YZMoviePlayerContentURLDidChangeNotification = @"YZMoviePlayerContentURLDidChangeNotification";

// block中弱引用self
#define WEAKSELF(object)   __weak __typeof__(object) weak##_##object = object;
#define STRONGSELF(object)  __typeof__(object) object = weak##_##object;

#define IOSVERSION [[[UIDevice currentDevice] systemVersion] floatValue]

static const CGFloat YZMovieBackgroundPadding = 20.f; //if we don't pad the movie's background view, the edges will appear jagged when rotating
static const NSTimeInterval YZFullscreenAnimationDuration = 0.25;


@implementation UIApplication (YZAppDimensions)

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    
    //防止不同iOS系统[UIScreen mainScreen].bounds.size颠倒的问题，所以取竖屏尺寸
    CGSize size = CGSizeMake(MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height), MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
    
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    if (!application.statusBarHidden && IOSVERSION < 7.0) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end

@interface YZMoviePlayerController () <X1PlayerAgentDelegate> {
    
    EAGLContext *_context;
    
    int _currentPos;
    int _retryPlayPos;
    int _movieDuration;
    int _playableDuration;
    
    UIView *_noNetworkView;
    UIView *_loadView;
    UIView *_tmpView;
}
//横屏情况下 self.view是它的子视图，因为视频旋转的时候可能出现锯齿边缘，填充视图用于抗锯齿
@property (nonatomic, strong) UIView *movieBackgroundView;

//缓冲超时计时器
@property (nonatomic, strong) NSTimer *timeoutTimer;


@end

@implementation YZMoviePlayerController

# pragma mark -- LifeCycle
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super init]) {
        self.view.frame = frame;
        self.view.backgroundColor =[UIColor blackColor];
        _retryPlayPos = -1;
        _isCompletion = NO;
        _movieFullscreen = NO;
        
        //初始化X1PlayerSDK
        [self initX1PlayerSDK];
        
        //抗锯齿背景视图
        if (!_movieBackgroundView) {
            _movieBackgroundView = [[UIView alloc] init];
            [_movieBackgroundView setBackgroundColor:[UIColor blackColor]];
        }
        
        //初始化控制层
        YZMoviePlayerControls *movieControls = [[YZMoviePlayerControls alloc] initWithMoviePlayer:self style:YZMoviePlayerControlsStyleDefault];
        
        [movieControls setTimeRemainingDecrements:NO];
        [self setControls:movieControls];
        
    }
    
    return self;
}


- (void)dealloc {
    
    _delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- Internal Method
// !!!:核心模块 初始化X1PlayerSDK
- (void)initX1PlayerSDK
{
    _playerSDK = [[X1Player alloc] initX1PlayerInstance:self];

    [_playerSDK Init];
    _playerMediaState = PS_NONE;
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:_context];
    [self.view addSubview:_glkView];
    [self.view sendSubviewToBack:_glkView];
    
    [_playerSDK setDisplay:_glkView];
    
}
//设置播放控制层风格
- (void)setupMovieControlsWithStyle:(YZMoviePlayerControlsStyle)style{
    
    [_controls setStyle:style];
}

// !!!:视频播放关键代码
- (void)setContentURL:(NSString *)contentURL {
    if (!_controls) {
        [[NSException exceptionWithName:@"YZMoviePlayerController Exception" reason:@"Set contentURL after setting controls." userInfo:nil] raise];
    }
    
    [self stop];
    _retryPlayPos = -1;
    _glkView.backgroundColor=[UIColor blackColor];
    self.mediasource = contentURL;
    [_playerSDK setDataSource:contentURL];
    
    if (self.isAutoPlay&& !self.isCountdownView) {//自动播放标识 非倒计时视图
        
        if (self.fatherView.networkMonitor.currentReachabilityStatus == ReachableViaWWAN && self.fatherView.isShowWWANViewInAutoPlay) { //流量环境 存在需要展示流量标识
            return;
        }
        
        [_playerSDK prepareAsync];
        [self setPlayerMediaState:PS_LOADING];
    }
    
}
//改变播放源
- (void)changeContentURL:(NSString *)contentURL{
   
    if (!_controls) {
        [[NSException exceptionWithName:@"YZMoviePlayerController Exception" reason:@"Set contentURL after setting controls." userInfo:nil] raise];
    }
    
    [self stop];
    _glkView.backgroundColor=[UIColor blackColor];
    self.mediasource = contentURL;
    
    
    [_playerSDK setDataSource:contentURL];
    
    if (self.isLive) {
        [_playerSDK prepareAsync];
        [self setPlayerMediaState:PS_LOADING];
    }else{
        
        _retryPlayPos = _currentPos;
        
        [self setCurrentPlaybackTime:floor(_retryPlayPos/1000)];
        
    }
  
    


    
}

//展示封面视图
-(void)showCoverView{
    
    [_coverView removeFromSuperview];
    
    _coverView =[[YZMoivePlayerCoverView alloc] initWithMoviePlayer:self];
    _coverView.frame = self.view.bounds;

    [self.view addSubview:_coverView];
    
}
//展示重播视图
-(void)showReplayView{
    
    [_replayView removeFromSuperview];
    
    _replayView =[[YZMoivePlayerReplayView alloc] initWithMoviePlayer:self];
    _replayView.frame = self.view.bounds;
    [self.view addSubview:_replayView];
    
    [_replayView showReplayViewWithBackBtn:_isNeedShowBackBtn];
}

- (void)changeTitle:(NSString*)title;
{
    self.controls.programTitle = title;
}

- (CGFloat)statusBarHeightInOrientation:(UIInterfaceOrientation)orientation {
    if (IOSVERSION <= 7.0){
        return 0.f;

    }
    else if ([UIApplication sharedApplication].statusBarHidden){
        return 0.f;

    }
    return [[UIApplication sharedApplication] statusBarFrame].size.height;
}


#pragma mark  -- Public Method

- (void)setupControlWithStyle:(YZMoviePlayerControlsStyle)style{
    
    
    //初始化控制层
    [self setupMovieControlsWithStyle:style];
    
    //展示封面层
    [self showCoverView];
}



//重设NoNetView frame
-(void)resetNoNetViewFrame:(CGRect)frame
{
    UIImageView *netImageView = (UIImageView *)[_noNetworkView viewWithTag:1];
    UILabel *tintLabel = (UILabel *)[_noNetworkView viewWithTag:2];
    UILabel *setLabel = (UILabel *) [_noNetworkView viewWithTag:3];
    [_noNetworkView setFrame:frame];
    if (_movieFullscreen) {
        [netImageView setFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 85, 110, 75)];
        [tintLabel setFrame:CGRectMake((self.view.bounds.size.width - 120)/2 , netImageView.frame.origin.y + 75 + 25, 120, 20)];
        [setLabel setFrame:CGRectMake((self.view.frame.size.width - 180)/2, tintLabel.frame.origin.y + 20 + 10, 180, 20)];
    } else {
        [netImageView setFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 30, 110, 75)];
        [tintLabel setFrame:CGRectMake((self.view.bounds.size.width - 100)/2 , netImageView.frame.origin.y + 75 + 15, 100, 20)];
        [setLabel setFrame:CGRectMake((self.view.frame.size.width - 180)/2, tintLabel.frame.origin.y + 20 + 7, 180, 20)];
    }
    
}
//重设LoadingView frame
-(void)resetLodingViewFrame:(CGRect)frame {
    UIImageView *loadImg = (UIImageView *)[_loadView viewWithTag:0];
    UILabel *percentLabel = (UILabel *)[_loadView viewWithTag:1];
    UILabel *loadLabel = (UILabel *) [_loadView viewWithTag:2];
    [_loadView setFrame:frame];
    if (_movieFullscreen) {
        [loadImg setFrame:CGRectMake((self.view.bounds.size.width - 90)/2, (self.view.bounds.size.height - 100)/2, 90, 100)];
        [percentLabel setFrame:CGRectMake(15, 30, 60, 20)];
        [loadLabel setFrame:CGRectMake(15, 70, 60, 20)];
    } else {
        [loadImg setFrame:CGRectMake((self.view.bounds.size.width - 90)/2, (self.view.bounds.size.height - 100)/2, 90, 100)];
        [percentLabel setFrame:CGRectMake(15, 30, 60, 20)];
        [loadLabel setFrame:CGRectMake(15, 70, 60, 20)];
    }
}

//LoadingView动画
-(void)lodingView:(int) percent
{
    if (_noNetworkView != nil) {
        NSLog(@"YZYZMovieplayerController has show noNetView");
        return;
    }
    [self.controls removeDataTimeOutView];
    if(_loadView == nil){
        //初始化loadview 及其子view
        _loadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 100)];
        _loadView.userInteractionEnabled = NO;
        _loadView.center = self.controls.center;
        //        loadView.backgroundColor = [UIColor colorWithRed:10/255 green:10/255 blue:10/255 alpha:0.9];
        _loadView.backgroundColor = [UIColor clearColor];
        UIImageView *loadImg = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 60, 60)];
        [loadImg setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_loding")]];
        [_loadView addSubview:loadImg];
        //图片旋转
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];
        rotationAnimation.duration = 1;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = NSNotFound;
        rotationAnimation.removedOnCompletion = NO;
        [loadImg.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        
        UILabel *percentLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 30, 60, 20)];
        percentLabel.textColor = YZColorFromRGB(0x249ff4);
        
        percentLabel.font = [UIFont systemFontOfSize:13.0f];
        percentLabel.textAlignment = NSTextAlignmentCenter;
        percentLabel.tag = 1;
        [_loadView addSubview:percentLabel];
        
        UILabel *loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 70, 60, 20)];
        loadLabel.textColor = YZColorFromRGB(0xb3b7ba);
        loadLabel.font = [UIFont systemFontOfSize:13.0f];
        loadLabel.textAlignment = NSTextAlignmentCenter;
        loadLabel.text = @"正在缓冲";
        [_loadView addSubview:loadLabel];
        [self.view addSubview:_loadView];
    }
    //通过tag拿到percentLabel
    UILabel *percentLabel = [_loadView viewWithTag:1];
    percentLabel.text = [[NSString stringWithFormat:@"%d",percent] stringByAppendingString:@"%"];
}

//移除LoadingView
-(void)removeloadview
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_loadView != nil && _loadView.superview != nil)
        {
            
            [_loadView removeFromSuperview];
            _loadView = nil;
        }
    });
}

//显示无网络视图
-(void)showNoNetView
{
    if (_loadView) {
        [_loadView removeFromSuperview];
        _loadView = nil;
    }
    //移除3S超时提示视图
    [self.controls removeDataTimeOutView];
    _noNetworkView = [[UIView alloc] initWithFrame:self.view.bounds];
    _noNetworkView.backgroundColor = [UIColor colorWithRed:10/255 green:10/255 blue:10/255 alpha:0.75];
    if (_movieFullscreen) {
        UIImageView *netImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 85, 110, 75)];
        [netImageView setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_no_network")]];
        netImageView.tag = 1;
        [_noNetworkView addSubview:netImageView];
        
        UILabel *tintLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 120)/2 , netImageView.frame.origin.y + 75 + 25, 120, 20)];
        tintLabel.text = @"哦哦~播放出错了";
        tintLabel.textAlignment = NSTextAlignmentCenter;
        tintLabel.font = [UIFont systemFontOfSize:14.0f];
        tintLabel.textColor = YZColorFromRGB(0xb3b7ba);
        tintLabel.tag = 2;
        [_noNetworkView addSubview: tintLabel];
        
        UILabel *setLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 180)/2, tintLabel.frame.origin.y + 20 + 10, 180, 20)];
        setLabel.font= [UIFont systemFontOfSize:11.f];
        NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:@"请检查您的网络设置，或者刷新看看"];
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(12, 4)];
        [content addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0xb3b7ba) range:NSMakeRange(0, 12)];
        [content addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0x54ac5d) range:NSMakeRange(12, 4)];
        setLabel.attributedText = content;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshMoviePlayer)];
        setLabel.userInteractionEnabled = YES;
        [setLabel addGestureRecognizer:tapRecognizer];
        setLabel.tag = 3;
        [_noNetworkView addSubview:setLabel];
    }else{
        UIImageView *netImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 30, 110, 75)];
        [netImageView setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_no_network")]];
        netImageView.tag = 1;
        [_noNetworkView addSubview:netImageView];
        
        UILabel *tintLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 100)/2 , netImageView.frame.origin.y + 75 + 15, 100, 20)];
        tintLabel.text = @"哦哦~播放出错了";
        tintLabel.textAlignment = NSTextAlignmentCenter;
        tintLabel.font = [UIFont systemFontOfSize:11.0f];
        tintLabel.textColor = YZColorFromRGB(0xb3b7ba);
        tintLabel.tag = 2;
        [_noNetworkView addSubview: tintLabel];
        
        UILabel *setLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 180)/2, tintLabel.frame.origin.y + 20 + 7, 180, 20)];
        setLabel.font= [UIFont systemFontOfSize:11.f];
        NSMutableAttributedString *content = [[NSMutableAttributedString alloc] initWithString:@"请检查您的网络设置，或者刷新看看"];
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:NSMakeRange(12, 4)];
        [content addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0xb3b7ba) range:NSMakeRange(0, 12)];
        [content addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0x54ac5d) range:NSMakeRange(12, 4)];
        setLabel.attributedText = content;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshMoviePlayer)];
        setLabel.userInteractionEnabled = YES;
        [setLabel addGestureRecognizer:tapRecognizer];
        setLabel.tag = 3;
        [_noNetworkView addSubview:setLabel];
    }
    [self.view addSubview:_noNetworkView];
}

//无网络视图点击"刷新看看"
-(void)refreshMoviePlayer{
    
    [_noNetworkView removeFromSuperview];
    _noNetworkView = nil;
    [self retryPlay];
    [self startTimeoutTimer];
}

#pragma mark -- 设备旋转相关处理
//设备旋转时调用
-(void)rorateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated{
    //弹回键盘
    [self.view endEditing:YES];
  
    
    if (self.isRealFullScreenBtnPress) {//如果是按下全屏按钮导致的调用，防止调用两次
        return;
    }
    //设置control样式
    [self.controls fullscreenPressedWithOrientation:orientation];
}

//全屏按钮点击时 && 设备旋转时  都会调用的方法
- (void)setFullscreen:(BOOL)fullscreen orientation:(UIInterfaceOrientation)orientation  animated:(BOOL)animated{
    
    //弹回键盘
    [self.view endEditing:YES];

    _movieFullscreen = fullscreen;
    
    //设备旋转的orientation标识判断全屏
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        
        if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerMoviePlayerWillEnterFullScreen)]) {
            [self.delegate yzMoviePlayerControllerMoviePlayerWillEnterFullScreen];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerWillEnterFullscreenNotification object:nil];
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
     
        if (CGRectEqualToRect(self.movieBackgroundView.frame, CGRectZero)) {
            [self.movieBackgroundView setFrame:CGRectMake(0, 0, MAX(window.bounds.size.height, window.bounds.size.width), MIN(window.bounds.size.height, window.bounds.size.width))];
        }
 
        [_fatherView addSubview:self.movieBackgroundView];
       
        //全屏隐藏状态栏
//        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

        [self.movieBackgroundView addSubview:self.view];
        [self rotateMoviePlayerForOrientation:orientation animated:animated completion:^{
          
                [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerDidEnterFullscreenNotification object:nil];
            
                //旋转完毕置为NO
                self.isRealFullScreenBtnPress = NO;
            
        }];
        
    } else {
        
        if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerMoviePlayerWillExitFullScreen)]) {
            [self.delegate yzMoviePlayerControllerMoviePlayerWillExitFullScreen];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerWillExitFullscreenNotification object:nil];
        
//        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
//
        [self.movieBackgroundView removeFromSuperview];
        
        [self rotateMoviePlayerForOrientation:UIInterfaceOrientationPortrait animated:animated completion:^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerDidExitFullscreenNotification object:nil];
            //处理完置为NO
            self.isRealFullScreenBtnPress = NO;
        }];
    }
    
    //控制层UI改变
    [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerMediaStateChangedNotification object:nil];

 
}
// !!!:屏幕旋转核心代码
- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^)(void))completion {
    
    if (self.isRealFullScreenBtnPress) {
        //屏幕旋转
        [self interfaceOrientation:orientation];
    }
    
    CGFloat angle;
    CGSize windowSize = [UIApplication sizeInOrientation:orientation];
    CGRect backgroundFrame;
    CGRect movieFrame;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            backgroundFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            movieFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI_2;
            backgroundFrame = CGRectMake([self statusBarHeightInOrientation:orientation] - YZMovieBackgroundPadding, -YZMovieBackgroundPadding, windowSize.height + YZMovieBackgroundPadding*2, windowSize.width + YZMovieBackgroundPadding*2);
            movieFrame = CGRectMake(YZMovieBackgroundPadding, YZMovieBackgroundPadding, backgroundFrame.size.height - YZMovieBackgroundPadding*2, backgroundFrame.size.width - YZMovieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            backgroundFrame = CGRectMake(-YZMovieBackgroundPadding, -YZMovieBackgroundPadding,MAX(windowSize.width, windowSize.height) + YZMovieBackgroundPadding*2,MIN(windowSize.width, windowSize.height) + YZMovieBackgroundPadding*2);
            movieFrame = CGRectMake(YZMovieBackgroundPadding, YZMovieBackgroundPadding, backgroundFrame.size.width - YZMovieBackgroundPadding*2, backgroundFrame.size.height - YZMovieBackgroundPadding*2);
          
            break;
        case UIInterfaceOrientationPortrait:
        default:
            angle = 0.f;
            backgroundFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            movieFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            break;
    }
    
    if (animated) {//这个动画其实没什么用
        [UIView animateWithDuration:YZFullscreenAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
            self.movieBackgroundView.frame = backgroundFrame;
            [self setFrame:movieFrame];

        } completion:^(BOOL finished) {
            if (completion)
                completion();
        }];
    } else {
//        self.movieBackgroundView.transform = CGAffineTransformMakeRotation(angle);
        self.movieBackgroundView.frame = backgroundFrame;
        [self setFrame:movieFrame];


        if (completion)
            completion();
    }

}

/**
 *  强制屏幕转屏
 *setFullscreen *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    
}

#pragma mark -- Timer
//启动缓冲超时计时器
-(void)startTimeoutTimer{
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(trigTimeoutAction) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSRunLoopCommonModes];

}
//停止缓冲超时计时器
-(void)stopTimeoutTimer{
    
    [self.timeoutTimer invalidate];
    self.timeoutTimer = nil;
    
}
//缓冲超时action
-(void)trigTimeoutAction{
    
    [self stopTimeoutTimer];

    [self showNoNetView];
    
    [self movieTimedOut];
}



#pragma mark --  Action
-(void)clickBackBtn{
    
    _isHitBackBtn = YES;
//    [self stop];
    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerOnClickBackBtn)]) {
        [self.delegate performSelector:@selector(yzMoviePlayerControllerOnClickBackBtn)];
    }
}

//全屏按钮被点击
-(void)clickFullScreenBtn{

    //改变全屏标识
    self.fullscreen = !self.isFullscreen;
    
    self.isRealFullScreenBtnPress = YES;
    
    if (self.fullscreen) {
        [self setFullscreen:self.fullscreen orientation:UIInterfaceOrientationLandscapeRight animated:YES];
    }else{
        [self setFullscreen:self.fullscreen orientation:UIInterfaceOrientationPortrait animated:YES];

    }
}

//播放暂停按钮被点击
-(void)clickPlayPauseBtn{
    
    if (self.getPlaybackState == PS_PLAYING) {
        
        [self pause];
        
    } else {
        
        [self play];
    }
}
//点击了悬浮小窗窗体
-(void)clickFloatView{

    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerOnClickFloatView)]) {
        [self.delegate performSelector:@selector(yzMoviePlayerControllerOnClickFloatView)];
    }
    
}
//点击了悬浮小窗关闭按钮
-(void)clickCloseFloatViewBtn{
  
    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerOnClickCloseFloatViewBtn)]) {
        [self.delegate yzMoviePlayerControllerOnClickCloseFloatViewBtn];
    }
}

#pragma mark -- Mediaplayer Control
//播放 直播重连 录播继续
- (void)play
{
        if (_currentPos == 0) {
            [_playerSDK prepareAsync];
        }else{
            if (self.isLive) {
                [_playerSDK restart];
                [self setPlayerMediaState:PS_PLAYING];

            }else{
                [_playerSDK resume];
                [self setPlayerMediaState:PS_PLAYING];

            }
      }

}
// 暂停
- (void)pause
{
    [self removeloadview];
    [_playerSDK pause];
    _retryPlayPos = _currentPos;
    [self setPlayerMediaState:PS_PAUSED];
}
//直播断点续播  录播继续播放
- (void)resume
{
    if (_currentPos==0) {
        [_playerSDK prepareAsync];
        
    } else {
        
       [_playerSDK resume];
       [self setPlayerMediaState:PS_PLAYING];

    }
    
}
//停止，不再缓冲
- (void)stop
{
    [self removeloadview];
    [_playerSDK stop];
    
    _retryPlayPos = _currentPos;
    [self setPlayerMediaState:PS_STOPED];
}

//播放出错进行的重连(直播刷新，点播调用会从断点继续播)
- (void)retryPlay
{
    [_playerSDK RetryPlay];
    
    _retryPlayPos = _currentPos;
    [self setPlayerMediaState:PS_RECONNECTION];
//    [self setPlayerMediaState:PS_LOADING];
}
//重新开始播放操作 (直播刷新，点播调用会从头开始播)
- (void)restart
{
    [_playerSDK restart];
    [self setPlayerMediaState:PS_RECONNECTION];
}

//定点播放
- (void)setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
    [_playerSDK seekTo:currentPlaybackTime * 1000.0];
    [self setPlayerMediaState:PS_SEEKTO];
}
//超时
-(void)movieTimedOut {
    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerMovieTimedOut)]) {
        [self.delegate performSelector:@selector(yzMoviePlayerControllerMovieTimedOut)];
    }
}

-(void)releasePlayer{
    [_playerSDK releasePlayer];
    
}

- (X1PlayerState)getPlaybackState
{
    return _playerMediaState;
}


#pragma mark - X1PlayerAgentDelegate回调

/** 播放加载回调
 这个方法只会在加载url的媒体资源的时候触发
 所以url不变 loadingflag:0 MediaState:PS_LOADING 调用一次
 loadingflag:1 MediaState:PS_BUFFERING 调用一次
 @param loadingflag 为1时表示媒体格式信息加载完成
 
 */
- (void) onLoading:(int) loadingflag
{
    if (loadingflag == 1) {
        
        [self setPlayerMediaState:PS_BUFFERING];
        _isLive = [_playerSDK isLive];
        NSLog(@"onLoading duration=%d",[_playerSDK getDuration]);
        
        [self removeloadview];

    } else {
        [self setPlayerMediaState:PS_LOADING];
        
        WEAKSELF(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weak_self lodingView:0];
            
            
        });
        
    }
}

/** 播放缓冲回调
 @param percent 已缓冲的百分比数(0-100)

 */
- (void) onBufferingUpdate:(int) percent
{
    
    if (percent < 100) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self lodingView:percent];
            //启动超时计时器
            if (!self.timeoutTimer) {
                [self  startTimeoutTimer];
            }
            
        });
    } else {
        [self removeloadview];
        [self setPlayerMediaState:PS_PLAYING];
        
    }
}


/** 播放开始回调
 在媒体预处理完成后调用
 同一个视频可能调用多次 每次缓冲100%调用一次
 */
- (void) onPrepared
{
    [self.controls removeDataTimeOutView];
    
    [_playerSDK start];
    _isCompletion = NO;
    [self setPlayerMediaState:PS_PLAYING];
    [self removeloadview];
    
    [self stopTimeoutTimer];
}



/** 当前播放时间实时显示回调
 @param currentPos 当前播放的时间,单位:ms
 */
- (void) onPlayingUpdate:(int) currentPos
{
//    NSLog(@"onPlayingUpdate currentPos=%d",currentPos);

//    [self removeloadview];
    _currentPos = currentPos;
    if (!_isCompletion) {
        [self setPlayerMediaState:PS_PLAYING];
    }

}

/** 播放完成回调

 */
- (void) onCompletion
{
    _isCompletion = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        _currentPos=0;
        _playableDuration=0;
        
        [self stop];
     
        //重设进度条及播放时间
        [self.controls resetMoveiPlayback:NO];
        
        [self.controls monitorMoviePlayableDuration];
        
//       //展示重播视图
//        [self showReplayView];

        
        
        //        //防止重播时视频显示最后一帧
        //        [_glkView removeFromSuperview];
        //        _glkView = nil;
        //        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        //        _glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:_context];
        //        [self.view addSubview:_glkView];
        //        [self.view sendSubviewToBack:_glkView];
        //        [_playerSDK setDisplay:_glkView];
        

        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerOnCompletionNotification object:nil];
        
        if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerPlayComplete)]) {
            [self.delegate yzMoviePlayerControllerPlayComplete];
        }
        
    });
 

}

/**
 快进快退回调

 */
- (void) onSeekComplete
{
    [self setPlayerMediaState:PS_PLAYING];
}

/** 错误处理回调
 @param what 错误码
 extra 额外的错误信息
 @return void
 */
- (BOOL) onError:(int) what extra:(int) extra
{
    NSLog(@"YZMoviePlayerController***************  onError:%d, extra:%d", what, extra);
    [self setPlayerMediaState:PS_ERROR];
    
    switch (what) {
        case ERROR_READ_MEDIA_FORMAT:
            //读取内容格式错误
            break;
        case ERROR_READ_DATA:
            //读取内容错误
            break;
        case ERROR_CONNECT_TIMEDOUT:
        {
            //网络连接超时
            break;
        }
        case ERROR_INIT_VIDEO_CODEC:
            //初始化视频解码器错误
            break;
        case ERROR_INIT_AUDIO_CODEC:
            //初始化音频解码器错误
            break;
        case ERROR_READ_TIMEDOUT:
        {
            //读内容超时，正在重试...
            break;
        }
        case ERROR_HOST_UNREACH:
        {
            //网络主机不可达，正在重试...
            break;
        }
        case ERROR_HOST_DOWN:
        {
            //网络主机已下线，正在重试...
            break;
        }
        case ERROR_CONNECT_REFUSED:
        {
            //网络连接被拒绝，正在重试...
            break;
        }
        case ERROR_NETWORK_DOWN:
        {
            //网络断开，正在重试...
            break;
        }
        case ERROR_NETWORK_UNREACH:
        {
            //网络不可达，正在重试...
            break;
        }
        case ERROR_NETWORK_RESET:
        {
            //网络被重置，正在重试...
            break;
        }
        case ERROR_CONNECT_ABORTED:
        {
            //连接被放弃，正在重试...
            break;
        }
        case ERROR_CONNECT_RESET:
        {
            //连接被重置，正在重试...
            break;
        }
        case ERROR_IO:
        {
            //网络IO错误，正在重试...
            break;
        }
        default:
            //播放错误
            break;
    }
    
    return YES;
}

/** 停止完成回调(会在当前线程立刻回调)

 */
- (void) onStopComplete
{
    [self setPlayerMediaState:PS_STOPED];

    if (_isHitBackBtn) {
      
        _isHitBackBtn= 0;
    }
}


/** 可播放时长回调
 @param playableDuration 可播放时长，单位ms
 */
- (void) onPlayableDuration:(int) playableDuration
{
    _playableDuration = playableDuration;
}

/** 播放器通知回调 onLoading的回调 =1时激活此回调
 @param NotifyID notify消息ID
 */
- (void)onNotify:(int)NotifyID {
    NSLog(@"X1Player onNotify NotifyID=%d",NotifyID);
    
    if (NotifyID == NOTIFY_DATA_TIMEDOUT)
    {
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            //数据接收超时：加载3秒没加载到数据
//            [self.controls showDataTimeOutView];
//
//        });
     
    }
}



# pragma mark - Setter && Getter

- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.controls setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.coverView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.replayView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [_glkView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self resetNoNetViewFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self resetLodingViewFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
}

- (BOOL)isFullscreen {
    return _movieFullscreen;
}

- (void)setFullscreen:(BOOL)fullscreen{
    
    _movieFullscreen = fullscreen;
}


- (void)setControls:(YZMoviePlayerControls *)controls {
    if (_controls != controls) {
        [_controls removeFromSuperview];
        _controls=nil;
        _controls = controls;
        _controls.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        [self.view addSubview:_controls];
    }
}

-(void)setControlsStyle:(YZMoviePlayerControlsStyle )controlsStyle{
    if (!_controls) {
        return;
    }
    
    [_controls setStyle:controlsStyle];
    
}
-(void)setCoverimage:(UIImage *)coverimage{
    
    _coverimage = coverimage;
    [self.coverView setupCoverImage:coverimage];
    
}

- (void)setPlayerMediaState:(X1PlayerState)state
{
    if (_playerMediaState != state) {
        
        _playerMediaState = state;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerMediaStateChangedNotification object:nil];
        });
    }
}

-(void)setIsNeedShowBackBtn:(BOOL)isNeedShowBackBtn{
    
    _isNeedShowBackBtn = isNeedShowBackBtn;
    
    self.controls.isNeedShowBackBtn = isNeedShowBackBtn;
    
}

-(void)setBarGradientColor:(UIColor *)barGradientColor{
    [self.controls setBarGradientColor:barGradientColor];
}


/**
 *  获取可播放时长
 */
- (NSTimeInterval)playableDuration
{
    
    return _playableDuration/1000.0;
    
}

/**
 获取当前时长
 */
- (NSTimeInterval)currentPlaybackTime
{
    return _currentPos / 1000.0;
}

/**
 *  获取视频时长
 */
- (NSTimeInterval)duration
{
    _movieDuration = [_playerSDK getDuration] /1000.0;
    
    return _movieDuration;
}


@end
