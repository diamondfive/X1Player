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


NSString * const YZMoviePlayerWillEnterFullscreenNotification = @"YZMoviePlayerWillEnterFullscreenNotification";
NSString * const YZMoviePlayerDidEnterFullscreenNotification = @"YZMoviePlayerDidEnterFullscreenNotification";
NSString * const YZMoviePlayerWillExitFullscreenNotification = @"YZMoviePlayerWillExitFullscreenNotification";
NSString * const YZMoviePlayerDidExitFullscreenNotification = @"YZMoviePlayerDidExitFullscreenNotification";
//播放完成回调
NSString * const YZMoviePlayerOnCompletionNotification = @"YZMoviePlayerOnCompletionNotification";
//播放状态变化通知
NSString * const YZMoviePlayerMediaStateChangedNotification = @"YZMoviePlayerMediaStateChangedNotification";

NSString * const YZMoviePlayerContentURLDidChangeNotification = @"YZMoviePlayerContentURLDidChangeNotification";

// block中弱引用self
#define WEAKSELF typeof(self) __weak weakSelf = self;

@implementation UIDevice (YZSystemVersion)

+ (float)iOSVersion {
    static float version = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return version;
}

@end

@implementation UIApplication (YZAppDimensions)

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    
    //防止不同iOS系统[UIScreen mainScreen].bounds.size颠倒的问题，所以取竖屏尺寸
    CGSize size = CGSizeMake(MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height), MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
    
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    if (!application.statusBarHidden && [UIDevice iOSVersion] < 7.0) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end

static const CGFloat movieBackgroundPadding = 20.f; //if we don't pad the movie's background view, the edges will appear jagged when rotating
static const NSTimeInterval fullscreenAnimationDuration = 0.25;

#define kRandomColor [UIColor colorWithRed:arc4random_uniform(256) / 255.0 green:arc4random_uniform(256) / 255.0 blue:arc4random_uniform(256) / 255.0 alpha:1]
#define kRandomFont [UIFont systemFontOfSize:15]

@interface YZMoviePlayerController () <X1PlayerAgentDelegate> {
    
    EAGLContext *_context;
    
    int _currentPos;
    int _retryPlayPos;
    int _movieDuration;
    int _playableDuration;
    
    UIView *noNetView;
    UIView *loadView;
    
    UIView *_tmpView;
}
@property (nonatomic, strong) NSURL *dataURL;
//self.view是它的子视图，因为视频旋转的时候可能出现锯齿边缘，填充视图用于抗锯齿
@property (nonatomic, strong) UIView *movieBackgroundView;

@end


@implementation YZMoviePlayerController

# pragma mark -- lifecycle

- (id)init {
    
    return [self initWithFrame:CGRectZero andStyle:YZMoviePlayerControlsStyleNone];
}

- (id)initWithFrame:(CGRect)frame andStyle:(YZMoviePlayerControlsStyle)style{
    if ( (self = [super init]) ) {

        self.view.frame = frame;
        self.view.backgroundColor = [UIColor blackColor];
        
        //核心模块
        [self initIPlayerSDK];
        
        _movieFullscreen = NO;
        if (!_movieBackgroundView) {
            _movieBackgroundView = [[UIView alloc] init];
            [_movieBackgroundView setBackgroundColor:[UIColor blackColor]];
        }
        //初始化控制层
        [self initMovieControlsWithStyle:style];
        
        [self initReplayView];

        [self initPlayView];
        
        
        _retryPlayPos = -1;
        _isCompletion = NO;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"YZYZMoviePlayerController 挂掉了");
    _delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


# pragma mark - Setter && Getter
- (void)setFrame:(CGRect)frame {
    [self.view setFrame:frame];
    [self.controls setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.coverView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [self.replayView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    [_glkView setFrame:self.controls.frame];
    [self resetNoNetViewFrame:self.controls.frame];
    [self resetLodingViewFrame:self.controls.frame];
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
    [self.coverView setIsNeedShowBackBtn:_isNeedShowBackBtn];
    [self.replayView setIsNeedShowBackBtn:_isNeedShowBackBtn];

}

-(void)setBarGradientColor:(UIColor *)barGradientColor{
    [self.controls setBarGradientColor:barGradientColor];
}

// !!!:视频播放关键代码
- (void)setContentURL:(NSURL *)contentURL {
    if (!_controls) {
        [[NSException exceptionWithName:@"YZMoviePlayerController Exception" reason:@"Set contentURL after setting controls." userInfo:nil] raise];
    }
    
    [self stop];
    _retryPlayPos = -1;
    _glkView.backgroundColor=[UIColor blackColor];
    self.dataURL = contentURL;
    [_playerSDK setDataSource:contentURL.absoluteString];
    
    if (self.isAutoPlay&& !self.isCountdownView) { //自动播放并且并非未开播视图
        [_playerSDK prepareAsync];
        [self setPlayerMediaState:PS_LOADING];
    }
    
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

#pragma mark -- Internal Method
// !!!:初始化X1PlayerSDK 核心模块
- (void)initIPlayerSDK
{
    _playerSDK = [[X1Player alloc] initX1PlayerInstance:self];

    [_playerSDK Init];
    NSLog(@"YZ X1PlayerSDK=%@ YZMoviePlayerController=%@",_playerSDK,self);
    _playerMediaState = PS_NONE;
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:_context];
    [self.view addSubview:_glkView];
    [self.view sendSubviewToBack:_glkView];
    
    [_playerSDK setDisplay:_glkView];
    
}
//初始化播放控制层
- (void)initMovieControlsWithStyle:(YZMoviePlayerControlsStyle)style
{
    YZMoviePlayerControls *movieControls = [[YZMoviePlayerControls alloc] initWithMoviePlayer:self style:style];
    //    [movieControls  setBarColor:[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.1]];
    //    [movieControls setBarGradientColor:[UIColor redColor]];
    
    [movieControls setTimeRemainingDecrements:NO];
    [self setControls:movieControls];
}
//初始化封面视图
-(void)initPlayView{
    [_coverView removeFromSuperview];
    _coverView =[[YZMoivePlayerNoStartView alloc] init];
    _coverView.moviePlayer = self;
    [self.view addSubview:_coverView];
    
}

-(void)initReplayView{
    
    if (!_replayView) {
        _replayView =[[YZMoivePlayerReplayView alloc] init];
        _replayView.moviePlayer = self;
        [self.view addSubview:_replayView];
    }
}



- (void)changeTitle:(NSString*)title;
{
    self.controls.programTitle = title;
}

- (CGFloat)statusBarHeightInOrientation:(UIInterfaceOrientation)orientation {
    if ([UIDevice iOSVersion] >= 7.0)
        return 0.f;
    else if ([UIApplication sharedApplication].statusBarHidden)
        return 0.f;
    return 20.f;
}



#pragma mark  -- Public Method

//重设无网络视图 frame
-(void)resetNoNetViewFrame:(CGRect)frame
{
    UIImageView *netImageView = (UIImageView *)[noNetView viewWithTag:1];
    UILabel *tintLabel = (UILabel *)[noNetView viewWithTag:2];
    UILabel *setLabel = (UILabel *) [noNetView viewWithTag:3];
    [noNetView setFrame:frame];
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
//重设loadingView frame
-(void)resetLodingViewFrame:(CGRect)frame {
    NSLog(@"YZYZMoviePlayerControllerResetLodingViewFrame isFullscreen=%d frame=%@",_movieFullscreen,NSStringFromCGRect(frame));
    UIImageView *loadImg = (UIImageView *)[loadView viewWithTag:0];
    UILabel *percentLabel = (UILabel *)[loadView viewWithTag:1];
    UILabel *loadLabel = (UILabel *) [loadView viewWithTag:2];
    [loadView setFrame:frame];
    if (_movieFullscreen) {
        [loadImg setFrame:CGRectMake((self.view.bounds.size.width - 90)/2, (self.view.bounds.size.height - 100)/2, 90, 100)];
        [percentLabel setFrame:CGRectMake(15, 30, 60, 20)];
        [loadLabel setFrame:CGRectMake(15, 70, 60, 20)];
        NSLog(@"YZYZMoviePlayerControllerResetLodingViewFrame loadImg=%@ percentLabel=%@ loadLabel=%@",NSStringFromCGRect(loadImg.frame),NSStringFromCGRect(percentLabel.frame),NSStringFromCGRect(loadLabel.frame));
    } else {
        [loadImg setFrame:CGRectMake((self.view.bounds.size.width - 90)/2, (self.view.bounds.size.height - 100)/2, 90, 100)];
        [percentLabel setFrame:CGRectMake(15, 30, 60, 20)];
        [loadLabel setFrame:CGRectMake(15, 70, 60, 20)];
        NSLog(@"YZYZMoviePlayerControllerResetLodingViewFrame loadImg=%@ percentLabel=%@ loadLabel=%@",NSStringFromCGRect(loadImg.frame),NSStringFromCGRect(percentLabel.frame),NSStringFromCGRect(loadLabel.frame));
    }
}

//加载视图动画
-(void)lodingView:(int) percent
{
    if (noNetView != nil) {
        NSLog(@"YZYZMovieplayerController has show noNetView");
        return;
    }
    [self.controls removeDataTimeOutView];
    if(loadView == nil){
        //初始化loadview 及其子view
        //loadView = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 90)/2, (self.view.bounds.size.height - 100)/2, 90, 100)];
        loadView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 100)];
        loadView.userInteractionEnabled = NO;
        loadView.center = self.controls.center;
        //        loadView.backgroundColor = [UIColor colorWithRed:10/255 green:10/255 blue:10/255 alpha:0.9];
        loadView.backgroundColor = [UIColor clearColor];
        UIImageView *loadImg = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 60, 60)];
        [loadImg setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_loding")]];
        [loadView addSubview:loadImg];
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
        [loadView addSubview:percentLabel];
        
        UILabel *loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 70, 60, 20)];
        loadLabel.textColor = YZColorFromRGB(0xb3b7ba);
        loadLabel.font = [UIFont systemFontOfSize:13.0f];
        loadLabel.textAlignment = NSTextAlignmentCenter;
        loadLabel.text = @"正在缓冲";
        [loadView addSubview:loadLabel];
        [self.view addSubview:loadView];
    }
    //通过tag拿到percentLabel
    UILabel *percentLabel = [loadView viewWithTag:1];
    percentLabel.text = [[NSString stringWithFormat:@"%d",percent] stringByAppendingString:@"%"];
}

//移除加载视图
-(void)removeloadview
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (loadView != nil && loadView.superview != nil)
        {
            [loadView removeFromSuperview];
            loadView = nil;
        }
    });
}

//显示无网络视图
-(void)showNoNetView
{
    if (loadView) {
        [loadView removeFromSuperview];
        loadView = nil;
    }
    [self.controls removeDataTimeOutView];
    noNetView = [[UIView alloc] initWithFrame:self.view.bounds];
    noNetView.backgroundColor = [UIColor colorWithRed:10/255 green:10/255 blue:10/255 alpha:0.75];
    if (_movieFullscreen) {
        UIImageView *netImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 85, 110, 75)];
        [netImageView setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_no_network")]];
        netImageView.tag = 1;
        [noNetView addSubview:netImageView];
        
        UILabel *tintLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 120)/2 , netImageView.frame.origin.y + 75 + 25, 120, 20)];
        tintLabel.text = @"哦哦~播放出错了";
        tintLabel.textAlignment = NSTextAlignmentCenter;
        tintLabel.font = [UIFont systemFontOfSize:14.0f];
        tintLabel.textColor = YZColorFromRGB(0xb3b7ba);
        tintLabel.tag = 2;
        [noNetView addSubview: tintLabel];
        
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
        [noNetView addSubview:setLabel];
    }else{
        UIImageView *netImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 110)/2, 30, 110, 75)];
        [netImageView setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_no_network")]];
        netImageView.tag = 1;
        [noNetView addSubview:netImageView];
        
        UILabel *tintLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 100)/2 , netImageView.frame.origin.y + 75 + 15, 100, 20)];
        tintLabel.text = @"哦哦~播放出错了";
        tintLabel.textAlignment = NSTextAlignmentCenter;
        tintLabel.font = [UIFont systemFontOfSize:11.0f];
        tintLabel.textColor = YZColorFromRGB(0xb3b7ba);
        tintLabel.tag = 2;
        [noNetView addSubview: tintLabel];
        
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
        [noNetView addSubview:setLabel];
    }
    [self.view addSubview:noNetView];
}

//无网络视图点击"刷新看看"
-(void)refreshMoviePlayer{
    NSLog(@"YZYZMoviePlayerController 点击刷新看看");
    [noNetView removeFromSuperview];
    noNetView = nil;
    [self retryPlay];
}

#pragma mark -- 设备旋转相关处理
//设备旋转时调用
-(void)rorateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated{
    NSLog(@"YZYZMoviePlayerController 设备旋转时调用 interfaceOrientation=%ld animated=%d",(long)orientation,animated);
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
    NSLog(@"YZYZMoviePlayerController 全屏按钮点击时 && 设备旋转时 调用 setFullscreen fullscreen=%d animated=%d",fullscreen,animated);
  
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
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerMediaStateChangedNotification object:nil];
//    });
    
 
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
            backgroundFrame = CGRectMake([self statusBarHeightInOrientation:orientation] - movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding*2, windowSize.width + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding*2, backgroundFrame.size.width - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, -movieBackgroundPadding,MAX(windowSize.width, windowSize.height) + movieBackgroundPadding*2,MIN(windowSize.width, windowSize.height) + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding*2, backgroundFrame.size.height - movieBackgroundPadding*2);
          
            break;
        case UIInterfaceOrientationPortrait:
        default:
            angle = 0.f;
            backgroundFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            movieFrame = CGRectMake(0,0,self.view.bounds.size.width,self.view.bounds.size.height);
            break;
    }
    
    if (animated) {//这个动画其实没什么用
        [UIView animateWithDuration:fullscreenAnimationDuration delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
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

#pragma mark --  Action
-(void)movieTimedOut {
    if (!self.loadState  || !self.loadState) {
        if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerMovieTimedOut)]) {
            [self.delegate performSelector:@selector(yzMoviePlayerControllerMovieTimedOut)];
        }
    }
}
-(void)backBtnPressed {
    
    _isHitBackBtn = YES;
//    [self stop];
    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerBackBtnPressed)]) {
        [self.delegate performSelector:@selector(yzMoviePlayerControllerBackBtnPressed)];
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

//悬浮小窗视频被点击
-(void)floatViewPressed{

    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerFloatViewPressed)]) {
        [self.delegate performSelector:@selector(yzMoviePlayerControllerFloatViewPressed)];
    }
    
}
//悬浮小窗关闭按钮被点击
-(void)closeFloatViewBtnPressed{
  
    if ([self.delegate respondsToSelector:@selector(yzMoviePlayerControllerCloseFloatViewBtnPressed)]) {
        [self.delegate yzMoviePlayerControllerCloseFloatViewBtnPressed];
    }
}

#pragma mark -- mediaplayer control
//播放 直播重连 录播继续
- (void)play
{
    if ([_playerSDK isLive]) {
        [self restart];
    } else {
        if (_currentPos==0) {
            //重新初始化并启动播放
            [self stop];
            [_playerSDK Init];
            [_playerSDK setDataSource:self.contentURL.absoluteString];
            [_playerSDK setDisplay:_glkView];
            [_playerSDK prepareAsync];
            
        } else {
            
            [self resume];
            [self setPlayerMediaState:PS_PLAYING];

        }
    }
}
// 暂停
- (void)pause
{
    [self removeloadview];
    [_playerSDK pause];
    if ([_playerSDK isLive]) {
        _retryPlayPos = _currentPos;
    }
    [self setPlayerMediaState:PS_PAUSED];
}
//直播录播 继续播放
- (void)resume
{
    if (_currentPos==0) {
        //重新初始化并启动播放
        [self stop];
        [_playerSDK Init];
        [_playerSDK setDataSource:self.contentURL.absoluteString];
        [_playerSDK setDisplay:_glkView];
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
    NSLog(@"YZMoviePlayerController retryPlay");
    [_playerSDK RetryPlay];
    _retryPlayPos = _currentPos;
    [self setPlayerMediaState:PS_RECONNECTION];
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
    NSLog(@"YZYZMoviePlayerController setCurrentPlaybackTime _playerMediaState=%ld",(long)_playerMediaState);
    [_playerSDK seekTo:currentPlaybackTime * 1000.0];
    [self setPlayerMediaState:PS_SEEKTO];
}

- (X1PlayerState)getPlaybackState
{
    return _playerMediaState;
}

- (NSURL *)contentURL
{
    return self.dataURL;
}

#pragma mark - X1PlayerAgentDelegate回调

/** 播放加载回调
 这个方法只会在加载url的媒体资源的时候触发 所以url不变 loadingflag:0 MediaState:PS_LOADING 调用一次
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
        
        WEAKSELF
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf lodingView:0];
        });
        
    }
}

/** 播放缓冲回调
 @param percent 已缓冲的百分比数(0-100)

 */
- (void) onBufferingUpdate:(int) percent
{
//    NSLog(@"onBufferingUpdate, percent:%d", percent);
    WEAKSELF
    if (percent < 100) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf lodingView:percent];
        });
    } else {
        [self removeloadview];
        [self setPlayerMediaState:PS_PLAYING];
        
    }
}


/** 播放开始回调
 在媒体预处理完成后调用

 */
- (void) onPrepared
{
    [self.controls removeDataTimeOutView];
    
    [_playerSDK start];
    _isCompletion = NO;
    [self setPlayerMediaState:PS_PLAYING];
    [self removeloadview];
}



/** 当前播放时间实时显示回调
 @param currentPos 当前播放的时间,单位:ms
 */
- (void) onPlayingUpdate:(int) currentPos
{
//    NSLog(@"onPlayingUpdate currentPos=%d",currentPos);

    [self removeloadview];
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
    
    WEAKSELF
    dispatch_async(dispatch_get_main_queue(), ^{

        _currentPos=0;
        _playableDuration=0;
        
        [weakSelf stop];
     
        //重设进度条及播放时间
        [weakSelf.controls resetMoveiPlayback:NO];
        
        
        [weakSelf.controls monitorMoviePlayableDuration];
        
    
        

//        //防止重播时视频显示最后一帧
//        [_glkView removeFromSuperview];
//        _glkView = nil;
//        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//        _glkView = [[GLKView alloc] initWithFrame:self.view.bounds context:_context];
//        [self.view addSubview:_glkView];
//        [self.view sendSubviewToBack:_glkView];
//        [_playerSDK setDisplay:_glkView];
       
        
        [[NSNotificationCenter defaultCenter] postNotificationName:YZMoviePlayerOnCompletionNotification object:nil];
        

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
    NSLog(@"YZYZMoviePlayerController***************  onError:%d, extra:%d", what, extra);
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

/** 交互数据回调
 @param data 交互数据。
 state 交互数据开始和结束状态，1=开始，0=结束。
 type 数据类型
 data_length 数据长度
 time_stamp 数据的时间戳
 */
- (void) onExtraData:(char*) data state:(int) state type:(short) type data_length:(short) data_length time_stamp:(int) time_stamp
{
    
}

/** 交互数据回调2
 @param state 交互数据开始和结束状态，1=开始，0=结束。
 type 数据类型
 data_length 数据长度
 time_stamp 数据的时间戳
 ADDatas 广告数据
 @return void
 */
- (void) onExtraData2:(int) state type:(short) type data_length:(short) data_length time_stamp:(int) time_stamp addatas:(X1ADDatas *) addatas{
    
    
}

/** 可播放时长回调
 @param playableDuration 可播放时长，单位ms
 */
- (void) onPlayableDuration:(int) playableDuration
{
    _playableDuration = playableDuration;
}

/** 播放器通知回调
 @param NotifyID notify消息ID
 */
- (void)onNotify:(int)NotifyID {
    NSLog(@"onNotify NotifyID=%d",NotifyID);
    if (NotifyID == NOTIFY_DATA_TIMEDOUT)
    {   //数据接收超时：加载时3秒没加载到数据
        [self.controls setDataTimeOutView];
    }
}






@end
