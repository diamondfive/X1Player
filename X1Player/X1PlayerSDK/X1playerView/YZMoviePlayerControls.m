//
//  YZMoviePlayerControls.h
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoviePlayerControls.h"
#import "YZMoviePlayerController.h"
#import <tgmath.h>
#import <QuartzCore/QuartzCore.h>
#import "YZMoviePlayerSlider.h"
#import "X1Player.h"
#import "YZMoviePlayerControlAdditionView.h"
#import "X1PlayerView.h"
#import "YZMutipleDefinitionModel.h"

#define YZStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

static const inline BOOL isIpad() {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

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

@interface YZMoviePlayerControls () <YZButtonDelegate> {
    
@private NSString *title;

}
@property (nonatomic, getter = isShowing) BOOL showing;
@property (nonatomic, strong) YZMoviePlayerControlAdditionView *controlAdditionView;//附加视图层
@property (nonatomic, strong) NSTimer *durationTimer; //每秒更新时间label slider
@property (nonatomic, strong) NSTimer *playableDurationTimer; // 每0.5s更新缓冲条
@property (nonatomic, strong) YZMoviePlayerSlider *durationSlider; //进度滑动条
@property (nonatomic, strong) YZMoviePlayerControlButton *playPauseButton;
@property (nonatomic, strong) YZMoviePlayerControlButton *fullscreenButton;
@property (nonatomic, strong) YZMoviePlayerControlButton *definitionBtn;//清晰度选择
@property (nonatomic, strong) UILabel *timeRemainingLabel;//显示为 播放时间
@property (nonatomic, strong) UILabel *timeTotalLabel; //显示为 总时间

@property (nonatomic, strong) YZMoviePlayerControlButton *backButton;

@property (nonatomic, strong) UILabel *titleLabel;//标题
@property (nonatomic, strong) UILabel *timeOutView_3S;//超时3秒
//当前设备方向,设备旋转时赋初值
@property (nonatomic, assign) UIInterfaceOrientation currentOrientation;
//渐变图层
@property (nonatomic, strong) UIView *topbarGradientView;
@property (nonatomic, strong) UIView *bottombarGradientView;
@property (nonatomic, strong) CAGradientLayer *topbarGradientLayer;
@property (nonatomic, strong) CAGradientLayer *bottombarGradientLayer;

@end


@implementation YZMoviePlayerControls

# pragma mark -- Lifecycle

- (id)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer style:(YZMoviePlayerControlsStyle)style{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _moviePlayer = moviePlayer;
        _style = style;

    
        [self initParam];
        [self setupConfigAndUI];
        [self addNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self nilDelegates];
}

// 根据横竖屏调整frame，frame改变会触发lauoutSubviews
- (void)layoutSubviews {
    [super layoutSubviews];
        
    if (self.style == YZMoviePlayerControlsStyleNone){
        return;
    }
    if (self.style == YZMoviePlayerControlsStyleFullscreen || (self.style == YZMoviePlayerControlsStyleDefault && self.moviePlayer.movieFullscreen)) {//录播横屏
        
        //top bar
        self.topBar.frame = CGRectMake(0, 0, self.frame.size.width,self.barHeight +20);
        self.backButton.frame = CGRectMake(15, 10+20, 20, 20);
        self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame)+10, CGRectGetMinY(self.backButton.frame), self.frame.size.width - CGRectGetMaxX(self.backButton.frame)-10-12, 20);
        
        //bottom bar
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);
        self.playPauseButton.frame = CGRectMake(25, 10, 20, 20);
        self.timeRemainingLabel.frame = CGRectMake(60, 0, 45, self.barHeight);
        self.fullscreenButton.frame = CGRectMake(self.frame.size.width-20-20, 10, 20, 20);
        
        CGFloat definitionBtnTotalWidth = 0;
        if (self.definitionBtn) {
            
            CGFloat width = [self.definitionBtn.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:kNilOptions attributes:@{NSFontAttributeName : self.definitionBtn.titleLabel.font ? : [UIFont systemFontOfSize:13]} context:nil].size.width;
            
            if (width > 100.0f || width <= 0) {
                width = 30;
            }
            
            self.definitionBtn.frame = CGRectMake(CGRectGetMinX(self.fullscreenButton.frame)-width-20, 10, width, 20);
            definitionBtnTotalWidth = width+20;
        }
        
        
        //slider bar
        self.durationSlider.frame = CGRectMake(CGRectGetMaxX(self.timeRemainingLabel.frame), 10, self.frame.size.width -CGRectGetMaxX(self.timeRemainingLabel.frame)-(45+15)-definitionBtnTotalWidth-(20+20), 20);
        [self.bottomBar bringSubviewToFront:self.durationSlider];
        
        self.timeTotalLabel.frame = CGRectMake(CGRectGetMaxX(self.durationSlider.frame), 0, 45, self.barHeight);
        
        
        
        
    } else if (self.style == YZMoviePlayerControlsStyleEmbedded || (self.style == YZMoviePlayerControlsStyleDefault && !self.moviePlayer.movieFullscreen)) {//录播竖屏
        
        //top bar
        if (_isNeedShowBackBtn) {
            self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight + 20);
            self.backButton.frame = CGRectMake(10, 20, 20, 20);
            
            self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame)+10, self.backButton.frame.origin.y, self.frame.size.width - CGRectGetMaxX(self.backButton.frame)-10-12, 20);
        }else{
            self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight);
            //            self.backButton.frame = CGRectMake(10, 10, 20, 20);
            
            self.titleLabel.frame = CGRectMake(20 ,10, self.frame.size.width -15-12, 20);
        }
        
        //bottom bar
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);
        self.playPauseButton.frame = CGRectMake(20, 10, 20, 20);
        self.timeRemainingLabel.frame = CGRectMake(50, 0, 40, self.barHeight);
        self.fullscreenButton.frame = CGRectMake(self.frame.size.width-20-15, 10, 20, 20);
        
        
        //slider bar
        self.durationSlider.frame = CGRectMake(CGRectGetMaxX(self.timeRemainingLabel.frame), 10, self.frame.size.width -CGRectGetMaxX(self.timeRemainingLabel.frame)-40-10-20-15 , 20);
        [self.bottomBar bringSubviewToFront:self.durationSlider];
        
        self.timeTotalLabel.frame = CGRectMake(CGRectGetMaxX(self.durationSlider.frame), 0, 40, self.barHeight);
        
    } else if (self.style == YZMoviePlayerControlsStyleLiveLandscape || (self.style == YZMoviePlayerControlsStyleLive && self.moviePlayer.movieFullscreen)){//直播横屏
        
        
        //top bar
        self.topBar.frame = CGRectMake(0, 0, self.frame.size.width,self.barHeight+20);
        self.backButton.frame = CGRectMake(15, 10+20, 20, 20);
        self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame) + 10, CGRectGetMinY(self.backButton.frame), self.frame.size.width - CGRectGetMaxX(self.backButton.frame) - 10 - 12, 20);
        
        //bottom bar
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);
        self.playPauseButton.frame = CGRectMake(25, 10, 20, 20);
        self.fullscreenButton.frame = CGRectMake(self.frame.size.width-20-20, 10, 20, 20);
        
        CGFloat definitionBtnTotalWidth = 0;
        if (self.definitionBtn) {
            
            CGFloat width = [self.definitionBtn.titleLabel.text boundingRectWithSize:CGSizeMake(MAXFLOAT, 20) options:kNilOptions attributes:@{NSFontAttributeName : self.definitionBtn.titleLabel.font ? : [UIFont systemFontOfSize:13]} context:nil].size.width;
            
            if (width > 100.0f || width <= 0) {
                width = 30;
            }
            
            self.definitionBtn.frame = CGRectMake(CGRectGetMinX(self.fullscreenButton.frame)-width-20, 10, width, 20);
            definitionBtnTotalWidth = width+20;
        }
        
        
    }else if (self.style == YZMoviePlayerControlsStyleLivePortrait || (self.style == YZMoviePlayerControlsStyleLive && !self.moviePlayer.movieFullscreen)){//直播竖屏
        
        
        //top bar
        if (_isNeedShowBackBtn) {
            self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight + 20);
            self.backButton.frame = CGRectMake(10, 20, 20, 20);
            
            self.titleLabel.frame = CGRectMake(CGRectGetMaxX(self.backButton.frame)+10, self.backButton.frame.origin.y, self.frame.size.width - CGRectGetMaxX(self.backButton.frame)-10-12, 20);
        }else{
            self.topBar.frame = CGRectMake(0, 0, self.frame.size.width, self.barHeight);
            //            self.backButton.frame = CGRectMake(10, 10, 20, 20);
            
            self.titleLabel.frame = CGRectMake(20, 10, self.frame.size.width -15-12, 20);
        }
        
        
        
        //bottom bar
        self.bottomBar.frame = CGRectMake(0, self.frame.size.height - self.barHeight, self.frame.size.width, self.barHeight);
        self.playPauseButton.frame = CGRectMake(20, 10, 20, 20);
        self.fullscreenButton.frame = CGRectMake(self.frame.size.width-20-15, 10, 20, 20);
        
        
        
        
    }else if (self.style == YZMoviePlayerControlsStyleFloatView){
        
        
        self.floatView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }
    
    //附加视图层
    self.controlAdditionView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    if (_timeOutView_3S) {
        _timeOutView_3S.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    }
    
    if (_barGradientColor) {
        self.topbarGradientView.frame =CGRectMake(0, 0, self.topBar.bounds.size.width, self.frame.size.height/3);
        self.topbarGradientLayer.frame = self.topbarGradientView.bounds;
        
        self.bottombarGradientView.frame = CGRectMake(0,self.barHeight -self.frame.size.height/3, self.bottomBar.bounds.size.width, self.frame.size.height/3);
        self.bottombarGradientLayer.frame = self.bottombarGradientView.bounds;
    }
    
    
    
    
}

#pragma mark -- Internal Method
//初始化参数
-(void)initParam{
    
    _showing = YES;
    _fadeDelay = 5.0f;
    _timeRemainingDecrements = NO;
    if (!_barColor) {
        _barColor = [UIColor colorWithRed:0/255 green:0/255 blue:0/255 alpha:0.25];
        
    }
    
    if (!_barGradientColor) {
        _barGradientColor =[UIColor blackColor];
    }
    
    _barHeight = 40.f;
    
}

//设置配置项和UI
- (void)setupConfigAndUI{

    //设置悬浮小窗
    [self setupFloatView];
    //设置附加视图层
    [self setupControlAdditionView];
    //设置清晰度选择按钮
    [self setupDefinitionBtn];
    
    
    
    //top bar
    _topBar = [[YZMoviePlayerControlsBar alloc] init];
    //bottom bar
    _bottomBar = [[YZMoviePlayerControlsBar alloc] init];
    
    if (_barGradientColor) {

        [self setBarGradientColor:_barGradientColor];
    }else{
        [self setBarColor:_barColor];

    }
    
    //返回按钮
    _backButton = [[YZMoviePlayerControlButton alloc] init];
    [_backButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateNormal];
    [_backButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateHighlighted];
    _backButton.delegate = self;
    
    
    // 标题
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textColor = YZColorFromRGB(0xffffff);
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.text = title;
    
    
    //播放暂停按钮
    _playPauseButton = [[YZMoviePlayerControlButton alloc] init];
    [_playPauseButton addTarget:self action:@selector(playPausePressed:) forControlEvents:UIControlEventTouchUpInside];
    _playPauseButton.delegate = self;
    
    //播放时间
    _timeRemainingLabel = [[UILabel alloc] init];
    _timeRemainingLabel.textColor = YZColorFromRGB(0xffffff);
    _timeRemainingLabel.textAlignment = NSTextAlignmentCenter;
    _timeRemainingLabel.adjustsFontSizeToFitWidth = YES;
    NSMutableAttributedString *attriString;
    attriString = [[NSMutableAttributedString alloc]initWithString:@"00:00"];
    [attriString addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0xffffff) range:NSMakeRange(0, 5)];

    _timeRemainingLabel.attributedText = attriString;
    _timeRemainingLabel.minimumScaleFactor = 0.5;
    
    //总时间
    _timeTotalLabel = [[UILabel alloc] init];
    _timeTotalLabel.textColor = YZColorFromRGB(0xffffff);
    _timeTotalLabel.textAlignment = NSTextAlignmentCenter;
    _timeTotalLabel.adjustsFontSizeToFitWidth = YES;
    NSMutableAttributedString *attriString2;
    attriString2 = [[NSMutableAttributedString alloc] initWithString:@"00:00"];
    [attriString2 addAttribute:NSForegroundColorAttributeName value:YZColorFromRGB(0xffffff) range:NSMakeRange(0, 5)];
//    _timeTotalLabel.textAlignment = NSTextAlignmentLeft;
    _timeTotalLabel.attributedText = attriString2;
    _timeTotalLabel.minimumScaleFactor = 0.5;
    
    
    //slider bar
    _durationSlider = [[YZMoviePlayerSlider alloc] init];
    _durationSlider.value = 0.0f;
    _durationSlider.middleValue = 0.0f;
    _durationSlider.thumbTintColor = [UIColor clearColor];
    _durationSlider.minimumTrackTintColor = YZColorFromRGB(0x0080ff);
    _durationSlider.middleTrackTintColor = [YZColorFromRGB(0xd0d1d1) colorWithAlphaComponent:0.6];
    _durationSlider.maximumTrackTintColor = [YZColorFromRGB(0xffffff) colorWithAlphaComponent:0.26];
    _durationSlider.slider.continuous = YES;
    _durationSlider.slider.userInteractionEnabled = YES;
    
    [_durationSlider.slider addTarget:self action:@selector(durationSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [_durationSlider.slider addTarget:self action:@selector(durationSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [_durationSlider.slider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside];
    [_durationSlider.slider addTarget:self action:@selector(durationSliderTouchEnded:) forControlEvents:UIControlEventTouchUpOutside];
    
    //滑块图片
    UIImage *thumbImage = [UIImage imageNamed:X1BUNDLE_Image(@"yz_video_progresspoint")];
    //注意这里要加UIControlStateHightlighted的状态，否则当拖动滑块时滑块将变成原生的控件
    [_durationSlider.slider setThumbImage:thumbImage forState:UIControlStateHighlighted];
    [_durationSlider.slider setThumbImage:thumbImage forState:UIControlStateNormal];
    
    
    //全屏按钮
    _fullscreenButton = [[YZMoviePlayerControlButton alloc] init];
    [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateNormal];
    [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateHighlighted];
    [_fullscreenButton addTarget:self action:@selector(fullscreenPressed:) forControlEvents:UIControlEventTouchUpInside];
    _fullscreenButton.delegate = self;
    
    
    if (_style == YZMoviePlayerControlsStyleFullscreen || (_style == YZMoviePlayerControlsStyleDefault && _moviePlayer.movieFullscreen)) {//录播全屏
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
        _timeRemainingLabel.font = [UIFont systemFontOfSize:13.f];
        _timeTotalLabel.font = [UIFont systemFontOfSize:13.f];
      
     
       [_backButton addTarget:self action:@selector(fullscreenPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_controlAdditionView];

        [self addSubview:_topBar];
        [self addSubview:_bottomBar];
        
        [_topBar addSubview:_backButton];
        [_topBar addSubview:_titleLabel];
        
        [_bottomBar addSubview:_playPauseButton];
        [_bottomBar addSubview:_durationSlider];
        [_bottomBar addSubview:_timeRemainingLabel];
        [_bottomBar addSubview:_timeTotalLabel];
        [_bottomBar addSubview:_definitionBtn];
        
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateNormal];
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateSelected];

        [_bottomBar addSubview:_fullscreenButton];
        
        
    } else if (_style == YZMoviePlayerControlsStyleEmbedded || (_style == YZMoviePlayerControlsStyleDefault && !_moviePlayer.isFullscreen)) { //录播竖屏
        _titleLabel.font = [UIFont systemFontOfSize:13.f];
        _timeRemainingLabel.font = [UIFont systemFontOfSize:12.f];
        _timeTotalLabel.font =[UIFont systemFontOfSize:12.f];
       
        [_backButton addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_controlAdditionView];

        [self addSubview:_topBar];
        [self addSubview:_bottomBar];
        
//        [_topBar addSubview:_backButton];
        [_topBar addSubview:_titleLabel];
        [_bottomBar addSubview:_playPauseButton];
        [_bottomBar addSubview:_durationSlider];
        [_bottomBar addSubview:_timeRemainingLabel];
        [_bottomBar addSubview:_timeTotalLabel];

        
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateNormal];
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateHighlighted];

        [_bottomBar addSubview:_fullscreenButton];
        

    }else if (_style == YZMoviePlayerControlsStyleLiveLandscape || (_style == YZMoviePlayerControlsStyleLive && _moviePlayer.isFullscreen)){//直播横屏
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
        _timeRemainingLabel.font = [UIFont systemFontOfSize:13.f];
        _timeTotalLabel.font =[UIFont systemFontOfSize:13.f];

     
        [_backButton addTarget:self action:@selector(fullscreenPressed:) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:_controlAdditionView];

        [self addSubview:_topBar];
        [self addSubview:_bottomBar];
        
        [_topBar addSubview:_backButton];
        [_topBar addSubview:_titleLabel];
        [_bottomBar addSubview:_playPauseButton];
//        [_bottomBar addSubview:_durationSlider];
//        [_bottomBar addSubview:_timeRemainingLabel];
//        [_bottomBar addSubview:_timeTotalLabel];

        [_bottomBar addSubview:_definitionBtn];

        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateNormal];
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateSelected];
        [_bottomBar addSubview:_fullscreenButton];
        
        
    }else if (_style == YZMoviePlayerControlsStyleLivePortrait || (_style == YZMoviePlayerControlsStyleLive && !_moviePlayer.isFullscreen)){//直播竖屏
        _titleLabel.font = [UIFont systemFontOfSize:13.f];
        _timeRemainingLabel.font = [UIFont systemFontOfSize:12.f];
        _timeTotalLabel.font =[UIFont systemFontOfSize:12.f];
   
        [_backButton addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:_controlAdditionView];

        [self addSubview:_topBar];
        [self addSubview:_bottomBar];
     
//        [_topBar addSubview:_backButton];
        [_topBar addSubview:_titleLabel];
        [_bottomBar addSubview:_playPauseButton];
//        [_bottomBar addSubview:_durationSlider];
//        [_bottomBar addSubview:_timeRemainingLabel];
//        [_bottomBar addSubview:_timeTotalLabel];

        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateNormal];
        [_fullscreenButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateHighlighted];

        [_bottomBar addSubview:_fullscreenButton];
        

    }else if (_style == YZMoviePlayerControlsStyleFloatView){//小窗
        
        [self addSubview:self.floatView];
        
    }

    //初始化完成之后隐藏控制层
    [self hideControls:nil];
    //隐藏附加视图层
    self.controlAdditionView.alpha = 0;
    
}


//设置附加视图层
-(void)setupControlAdditionView{
    if (self.controlAdditionView) {
        [self.controlAdditionView removeFromSuperview];
        self.controlAdditionView = nil;
    }
    
        self.controlAdditionView = [[YZMoviePlayerControlAdditionView alloc] init];
        self.controlAdditionView.controls = self;
        self.controlAdditionView.mediasourceDefinitionArr = self.moviePlayer.mediasourceDefinitionArr;
    
}

// 设置悬浮小窗
-(void)setupFloatView{
    if (!self.floatView) {
        //悬浮小窗
        self.floatView =[[YZMoivePlayerFloatView alloc] init];
        self.floatView.controls = self;
    }

}

// 设置清晰度选择按钮
-(void)setupDefinitionBtn{
    
    if (self.moviePlayer.mediasourceDefinitionArr.count) {
        
        for (YZMutipleDefinitionModel *model in self.moviePlayer.mediasourceDefinitionArr) {
            
            if ([model.url isEqual:self.moviePlayer.mediasource]) {
                
                model.isSelected = YES;
                
                [self.definitionBtn setTitle:model.title? :@"默认" forState:UIControlStateNormal];
               
                
                break;
            }
            
        }
    
    }else{
        [self.definitionBtn removeFromSuperview];
        self.definitionBtn = nil;
    }
    
}


//播放暂停导致的样式改变
-(void)setPlayOrPauseStatus:(X1PlayerState)playBackState{
    
    
    if(playBackState == PS_PLAYING){// 播放中，需要显示暂停按钮
        
        if (self.moviePlayer.isFullscreen) {
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_pause_sel")] forState:UIControlStateNormal];
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_pause_sel")] forState:UIControlStateHighlighted];
        }else{
            
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_pause_nor")] forState:UIControlStateNormal];
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_pause_sel")] forState:UIControlStateHighlighted];
        }
        
        
    }else{//未播放，需要显示播放按钮
        
        if (self.moviePlayer.movieFullscreen) {
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_play_sel")] forState:UIControlStateNormal];
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_play_sel")] forState:UIControlStateHighlighted];
        }else{
            
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_play_nor")] forState:UIControlStateNormal];
            [_playPauseButton setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_play_sel")] forState:UIControlStateHighlighted];
        }
        
        
    }
    
    if (self.moviePlayer.isLive) {
        NSLog(@"是直播，进度条隐藏");
        self.durationSlider.alpha = 0;
        self.durationSlider.userInteractionEnabled = NO;
    } else {
        NSLog(@"不是直播，进度条显示");
        self.durationSlider.alpha = 1;
        self.durationSlider.userInteractionEnabled = YES;
    }
}
//移除视图 停用计时器
- (void)resetViews {
    [self stopDurationTimer];
    [self stopPlayableDurationTimer];
    [self nilDelegates];
    [self allControlsViewRemoveFromSuperView];
}

-(void)allControlsViewRemoveFromSuperView{
    
    [_topBar removeFromSuperview];
    [_bottomBar removeFromSuperview];
    [_floatView removeFromSuperview];
    
//    [self.moviePlayer.coverView showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
//    [self.moviePlayer.replayView showReplayViewWithBackBtn:NO];

    
}

- (void)nilDelegates {
    _playPauseButton.delegate = nil;
    _fullscreenButton.delegate = nil;
    _fullscreenButton.delegate = nil;
}


//配置topBar bottomBar渐变图层
-(void)configBarGradientLayer{
    
    if(self.topbarGradientView){
        [self.topbarGradientView removeFromSuperview];
    }
    if(self.bottombarGradientView){
        [self.bottombarGradientView removeFromSuperview];
    }
    
    //添加自定义背景
    self.topbarGradientView =[[UIView alloc] init];
    self.topbarGradientView.userInteractionEnabled = NO;
    self.topbarGradientLayer = [CAGradientLayer layer];
    self.topbarGradientLayer.colors = @[(id)[_barGradientColor colorWithAlphaComponent:0.7].CGColor, (id)[_barGradientColor colorWithAlphaComponent:0].CGColor];
    self.topBar.backgroundColor = [UIColor clearColor];
    [self.topBar addSubview:self.topbarGradientView];
    [self.topBar sendSubviewToBack:self.topbarGradientView];
    [self.topbarGradientView.layer addSublayer:self.topbarGradientLayer];
    
    
    self.bottombarGradientView = [[UIView alloc] init];
    self.bottombarGradientView.userInteractionEnabled = NO;
    self.bottombarGradientLayer =[CAGradientLayer layer];
    self.bottombarGradientLayer.colors = @[(id)[_barGradientColor colorWithAlphaComponent:0].CGColor,(id)[_barGradientColor colorWithAlphaComponent:0.7].CGColor];
    self.bottomBar.backgroundColor =[UIColor clearColor];
    [self.bottomBar addSubview:self.bottombarGradientView];
    [self.bottomBar sendSubviewToBack:self.bottombarGradientView];
    [self.bottombarGradientView.layer addSublayer:self.bottombarGradientLayer];
    
}


#pragma mark -- Public Method
// 设备旋转时调用的方法
-(void)fullscreenPressedWithOrientation:(UIInterfaceOrientation)orientation{
    
    self.currentOrientation = orientation;
    
    [self fullscreenPressed:nil];
    
    
}


#pragma mark -- Action
//点击了悬浮小窗
-(void)floatViewClick:(id)sender{
    
    [self.moviePlayer clickFloatView];
}

//点击了悬浮小窗叉号
-(void)closeFloatViewButtonClick:(UIButton *)sender{
    
    [self.moviePlayer clickCloseFloatViewBtn];
    
}

//点击了返回按钮
-(void)backBtnClick:(UIButton *)sender{
    NSLog(@"backBtnClick");
    [self.moviePlayer clickBackBtn];
}

//竖屏返回按钮被点击
- (void)backBtnPressed:(UIButton *)sender {
    NSLog(@"QNYZMovieControls backBtnPressed");
    [self.moviePlayer clickBackBtn];
}


//点击了开始暂停按钮
- (void)playPausePressed:(UIButton *)button {
    
    if (!self.moviePlayer.mediasource) {
        
        return;
    }
    
    if (self.moviePlayer.playerMediaState == PS_PLAYING) {
        
        [self.moviePlayer pause];
        
    } else {
        
        [self.moviePlayer resume];
    }
    
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

//全屏按钮点击的处理
- (void)fullscreenPressed:(UIButton *)button {
    
    //改变全屏标识
    self.moviePlayer.movieFullscreen = !self.moviePlayer.movieFullscreen;
    
    //1 重写setter方法改变样式
    if (self.style == YZMoviePlayerControlsStyleDefault) {
        self.style = self.moviePlayer.movieFullscreen ? YZMoviePlayerControlsStyleFullscreen : YZMoviePlayerControlsStyleEmbedded;
    }else if (self.style == YZMoviePlayerControlsStyleLive) {
        
        self.style = self.moviePlayer.movieFullscreen ? YZMoviePlayerControlsStyleLiveLandscape :
        YZMoviePlayerControlsStyleLivePortrait;
    }
    
    // 2  这个先后顺序 是为了先setup重新添加视图 然后调用了stateChangeCauseControlsUIChange 控制UI显隐
    if (button) { //真的点击了全屏按钮
        self.moviePlayer.isRealFullScreenBtnPress = YES;
        
        //改变设备标识
        if (self.moviePlayer.movieFullscreen) {
            self.currentOrientation = UIInterfaceOrientationLandscapeRight;
        }else{
            self.currentOrientation = UIInterfaceOrientationPortrait;
        }
        
        [self.moviePlayer setFullscreen:self.moviePlayer.movieFullscreen orientation:self.currentOrientation animated:YES];
        
    }else{//设备旋转导致的
        self.moviePlayer.isRealFullScreenBtnPress = NO;
        
        [self.moviePlayer setFullscreen:self.moviePlayer.movieFullscreen orientation:self.currentOrientation animated:YES];
        
    }
    
}
//点击清晰度选择按钮
-(void)clickDefinitioBtn:(UIButton *)sender{
    
    [self.controlAdditionView clickDefinitioBtn];
    
}


# pragma mark - slider events

- (void)durationSliderTouchBegan:(UISlider *)slider {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
//    [self.moviePlayer pause];
    //停用计时器
    [self stopDurationTimer];
}

- (void)durationSliderTouchEnded:(UISlider *)slider {
    [self.moviePlayer setCurrentPlaybackTime:floor(slider.value * self.moviePlayer.duration)];
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];


}

- (void)durationSliderValueChanged:(UISlider *)slider {
    
    double totalTime = floor(self.moviePlayer.duration);
    double currentTime = floor(slider.value * self.moviePlayer.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
}


# pragma mark -- Notifications

- (void)addNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangeCauseControlsUIChange) name:YZMoviePlayerMediaStateChangedNotification object:nil];
    // invalid
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieContentURLDidChange:) name:YZMoviePlayerContentURLDidChangeNotification object:nil];

}

// !!!:播放状态改变时的回调(全屏旋转也触发此回调，因为涉及UI的显示隐藏)
- (void)stateChangeCauseControlsUIChange
{
    int state = [self.moviePlayer playerMediaState];
    switch (state) {
        case PS_NONE:
            [self stopDurationTimer];
            [self stopPlayableDurationTimer];
            [self setPlayOrPauseStatus:PS_NONE];
            [self hideControls:nil];
           
            self.controlAdditionView.alpha = 0;
            
            break;
        case PS_PLAYING:
   
            [self setPlayOrPauseStatus:PS_PLAYING];
            [self startDurationTimer];
            
            //播放状态下切换全屏不再次显示控制层
            if (self.currentOrientation == UIInterfaceOrientationLandscapeLeft || self.currentOrientation == UIInterfaceOrientationLandscapeRight) {
                [self hideControls:nil];
            }else{
                [self showControls:nil autoHide:YES];
                
            }

            self.controlAdditionView.alpha = 1;
            if (self.moviePlayer.isLive) {
                self.controlAdditionView.isNeedShowFastforward = NO;
            }else{
                self.controlAdditionView.isNeedShowFastforward = YES;
                
            }
            
//            //播放本地文件
//            if ([self.moviePlayer.contentURL.scheme isEqualToString:@"file"]) {
//                [self setDurationSliderMaxMinValues];
//                [self showControls:nil autoHide:YES];
//            }
            break;
        case PS_SEEKTO:
            
            break;
        case PS_LOADING:
       
            [self hideControls:nil];
            self.controlAdditionView.alpha = 0;
            
            break;
        case PS_PAUSED:
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];

            [self setPlayOrPauseStatus:PS_PAUSED];
            [self stopDurationTimer];
            [self showControls:nil autoHide:NO];
            self.controlAdditionView.alpha = 1;
            
            break;
            //视频的开始和结束
        case PS_STOPED:
            [self stopDurationTimer];
            [self stopPlayableDurationTimer];
            [self setPlayOrPauseStatus:PS_STOPED];
            [self.durationTimer invalidate];
            
            [self hideControls:nil];
            self.controlAdditionView.alpha = 0;
            
     
            
            break;
        case PS_BUFFERING:
            
            
            [self hideControls:nil];
            self.controlAdditionView.alpha = 0;
            
            break;
        default:
            break;
    }
    
}

# pragma mark -- Timer
//启动计时器
- (void)startDurationTimer {
    if (self.moviePlayer.mediasource != nil) {
        if (self.durationTimer) {
            [self.durationTimer invalidate];
        }
        if (self.playableDurationTimer) {
            [self.playableDurationTimer invalidate];
        }
        self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(monitorMoviePlayback) userInfo:nil repeats:YES];
        self.playableDurationTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(monitorMoviePlayableDuration) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:self.durationTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop mainRunLoop] addTimer:self.playableDurationTimer forMode:NSRunLoopCommonModes];
    }
}

//停止播放时间更新计时器
- (void)stopDurationTimer {
    [self.durationTimer invalidate];
    self.durationTimer = nil;
}
//停止缓冲进度条更新计时器
- (void)stopPlayableDurationTimer {
    [self.playableDurationTimer invalidate];
    self.playableDurationTimer = nil;
}
//durationTimer 计时器调用的方法 每秒更新时间label slider
- (void)monitorMoviePlayback {
    NSTimeInterval currentPlaybackTime = self.moviePlayer.currentPlaybackTime;
    double currentTime;
    if (isnan(currentPlaybackTime)) {
        currentTime = 0;
    } else {
        currentTime=floor(currentPlaybackTime);
    }
    double totalTime = floor(self.moviePlayer.duration);
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    
    if (self.moviePlayer.duration > 0) {
        self.durationSlider.value = currentTime / totalTime;
    }
}

#pragma mark -- 显示隐藏 控制层
//显示控制层
- (void)showControls:(void(^)(void))completion autoHide:(BOOL)autohide{
    
    //锁屏情况处理
    if (self.isLocked &&!self.isShowing) {
         _showing = YES;
        [UIView animateWithDuration:0.3 animations:^{
            self.controlAdditionView.lockBtn.alpha = 1.f;
            self.topBar.alpha = 0.f;
            self.bottomBar.alpha = 0.f;
        }];
        
    }else if(self.isLocked &&self.isShowing){
        if (completion)
            completion();
        if (autohide) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
            
            [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
            
        }
        
    }
    
   //非锁屏情况处理
    if (!self.isShowing) {
        
        _showing = YES;
        
        if (self.moviePlayer.movieFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO];

        }else{
            [[UIApplication sharedApplication] setStatusBarHidden:NO];

        }
        
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
        
        [self.topBar setNeedsDisplay];
        [self.bottomBar setNeedsDisplay];
        [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
            
            self.topBar.alpha = 1.f;
            self.bottomBar.alpha = 1.f;
            self.controlAdditionView.lockBtn.alpha = 1.f;
            
        } completion:^(BOOL finished) {
            if (completion)
                completion();
            if (autohide) {
    
                [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
                
            }
        }];
    } else {
        if (completion)
            completion();
        if (autohide) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
            
            [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
        
        }
    }
    
}
//隐藏控制层
- (void)hideControls:(void(^)(void))completion{
    
    //锁屏情况处理
    if (self.isLocked&&self.isShowing) {
        _showing = NO;
        if (self.moviePlayer.movieFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            
        }else{
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            self.topBar.alpha = 0.f;
            self.bottomBar.alpha = 0.f;
            self.controlAdditionView.lockBtn.alpha = 0.f;
        }];
        
    }else if(self.isLocked&&!self.isShowing){
        if (completion)
            completion();
    }
    
    //非锁屏情况处理
    if (self.isShowing)
    {
        _showing = NO;
        
        if (self.moviePlayer.movieFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            
        }else{
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            
        }
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];

            [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
                self.topBar.alpha = 0.f;
                self.bottomBar.alpha = 0.f;
                self.controlAdditionView.lockBtn.alpha = 0.f;
                
            } completion:^(BOOL finished) {
                if (completion)
                    completion();
            }];

    } else {
        if (completion)
            completion();
    }
    
    
}

#pragma mark  --时间格式处理 显示在timeRemainingLabel上面
- (void)setTimeLabelValues:(double)currentTime totalTime:(double)totalTime {
    if (currentTime>totalTime && !_moviePlayer.isLive) {
        return;
    }
    double hoursElapsed = floor(currentTime / 3600.0);
    double minutesElapsed = floor(currentTime/60.0);
    double secondsElapsed = fmod(currentTime, 60.0);
    
    double hoursRemaining;
    double minutesRemaining;
    double secondsRemaining;
    if (self.timeRemainingDecrements) {
        hoursRemaining = floor((totalTime - currentTime) / 3600.0);
        minutesRemaining = floor((totalTime - currentTime)/60.0);
        secondsRemaining = fmod((totalTime - currentTime), 60.0);
    } else {
        hoursRemaining = floor(totalTime / 3600.0);
        minutesRemaining = floor(totalTime/ 60.0);
        secondsRemaining = floor(fmod(totalTime, 60.0));
    }
    NSString *tipText;
    NSString *totalText;
    if (_moviePlayer.isLive) {
        if (hoursElapsed > 0) {
            tipText = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
            
        } else {
            tipText = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
        }
    } else {
        //        if (hoursRemaining > 0) {
        tipText = [NSString stringWithFormat:@"%02.0f:%02.0f", minutesElapsed, secondsElapsed];
        
        totalText = [NSString stringWithFormat:@"%02.0f:%02.0f",minutesRemaining, secondsRemaining];
        //        } else {
        //            tipText = [NSString stringWithFormat:@"%02.0f:%02.0f/%02.0f:%02.0f", minutesElapsed, secondsElapsed, minutesRemaining, secondsRemaining];
        //        }
    }
    self.timeRemainingLabel.text = tipText;
    self.timeRemainingLabel.textColor = [UIColor whiteColor];
    self.timeTotalLabel.text = totalText;
    self.timeTotalLabel.textColor =[UIColor whiteColor];
    
    self.durationSlider.value = currentTime / totalTime;
}


//数据接收超时：加载时3秒没加载到数据
-(void)showDataTimeOutView
{
    if (_timeOutView_3S) {
        [_timeOutView_3S removeFromSuperview];
    }
    _timeOutView_3S = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 210, 20)];
    [_timeOutView_3S setFont:[UIFont systemFontOfSize:12]];
    _timeOutView_3S.textAlignment = NSTextAlignmentCenter;
    [_timeOutView_3S setTextColor:YZColorFromRGB(0xffffff)];
    _timeOutView_3S.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _timeOutView_3S.text = @"播放器正在玩命加载中，请稍后…";
    [self.moviePlayer.view addSubview:_timeOutView_3S];
}

//移除3S超时提示视图
-(void)removeDataTimeOutView
{
    if (_timeOutView_3S) {
        [_timeOutView_3S removeFromSuperview];
        _timeOutView_3S = nil;
    }
}

#pragma mark  -- 改变播放源,重设进度条及播放时间
- (void)resetMoveiPlayback:(BOOL) changeURL
{
    double currentTime = 0;
    double totalTime;
    if (changeURL) {
        totalTime = 0;
    } else {
        totalTime = floor(self.moviePlayer.duration);
    }
    self.moviePlayer.isLive=0;
    [self setTimeLabelValues:currentTime totalTime:totalTime];
    //    self.durationSlider.value = currentTime / totalTime;
    self.durationSlider.value = 0;
    
    if (changeURL) {
//        [self.replayView showReplayView:NO backBtn:NO];
    }
}
#pragma mark --playableDurationTimer调用的方法 每0.5S更新缓冲条的进度
- (void)monitorMoviePlayableDuration {
    double playableDuration = floor(self.moviePlayer.playableDuration);
    if (self.moviePlayer.duration > 0) {
        self.durationSlider.middleValue = playableDuration / self.moviePlayer.duration;
        if (playableDuration == self.moviePlayer.duration) {
            [self stopPlayableDurationTimer];
        }
    }
}


#pragma mark --  YZButtonDelegate
- (void)buttonTouchedDown:(UIButton *)button {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControls:) object:nil];
}

- (void)buttonTouchedUpOutside:(UIButton *)button {
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}

- (void)buttonTouchCancelled:(UIButton *)button {
    [self performSelector:@selector(hideControls:) withObject:nil afterDelay:self.fadeDelay];
}


#pragma mark -- touch event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

    [super touchesBegan:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
        
    [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    [super touchesEnded:touches withEvent:event];

}

#pragma mark  -- setter && getter

-(void)setProgramTitle:(NSString*)programTitle
{
    title = programTitle;
    self.titleLabel.text = programTitle;
}

-(void)setIsNeedShowBackBtn:(BOOL)isNeedShowBackBtn{
    
    _isNeedShowBackBtn = isNeedShowBackBtn;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
}

-(void)setIsLocked:(BOOL)isLocked{
    
    _isLocked = isLocked;
    
    self.moviePlayer.isLocked = isLocked;
    
    if (isLocked) {

        _showing = NO;
        [self showControls:nil autoHide:YES];

    }else{
        _showing = NO;
        [self showControls:nil autoHide:YES];
    }
    
}

- (void)setDurationSliderMaxMinValues {
    self.durationSlider.value = 0.0f;
    //    CGFloat duration = self.moviePlayer.duration;
    //    self.durationSlider.slider.maximumValue = duration;
}


- (void)setBarColor:(UIColor *)barColor {
    _barColor = barColor;
    
    [self.topBar setColor:barColor];
    [self.bottomBar setColor:barColor];
    
    
}

-(void)setBarGradientColor:(UIColor *)barGradientColor{
    
    _barGradientColor = barGradientColor;
    
    [self configBarGradientLayer];
    
}

-(void)setSliderMinimumTrackTintColor:(UIColor *)sliderMinimumTrackTintColor{
    _sliderMinimumTrackTintColor = sliderMinimumTrackTintColor;
    _durationSlider.minimumTrackTintColor = sliderMinimumTrackTintColor;
}

- (void)setSliderMiddleTrackTintColor:(UIColor *)sliderMiddleTrackTintColor{
    _sliderMiddleTrackTintColor = sliderMiddleTrackTintColor;
    _durationSlider.middleTrackTintColor = sliderMiddleTrackTintColor;
}

-(void)setSliderMaximumTrackTintColor:(UIColor *)sliderMaximumTrackTintColor{
    _sliderMaximumTrackTintColor = sliderMaximumTrackTintColor;
    _durationSlider.maximumTrackTintColor = sliderMaximumTrackTintColor;
}

-(void)setSliderThumbImage:(UIImage *)sliderThumbImage{
    
    _sliderThumbImage = sliderThumbImage;
    [_durationSlider.slider setThumbImage:sliderThumbImage forState:UIControlStateHighlighted];
    [_durationSlider.slider setThumbImage:sliderThumbImage forState:UIControlStateNormal];
    
}

-(YZMoviePlayerControlButton *)definitionBtn{
    
    if (!_definitionBtn) {
        _definitionBtn = [[YZMoviePlayerControlButton alloc] init];
        
        [_definitionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _definitionBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        
        [_definitionBtn addTarget:self action:@selector(clickDefinitioBtn:) forControlEvents:UIControlEventTouchUpInside];
        _definitionBtn.delegate = self;
    }
    return _definitionBtn;
}


// 重设风格,改变控制层样式和横竖屏旋转时触发
- (void)setStyle:(YZMoviePlayerControlsStyle)style {
    if (_style != style) {
        YZMoviePlayerControlsStyle lastStyle;
        if (
            (_style == YZMoviePlayerControlsStyleDefault && (style == YZMoviePlayerControlsStyleEmbedded || style == YZMoviePlayerControlsStyleFullscreen))
            ||
            (_style == YZMoviePlayerControlsStyleLive && (style == YZMoviePlayerControlsStyleLivePortrait || style == YZMoviePlayerControlsStyleLiveLandscape))
            ) {
            
            lastStyle = _style;
            
        }else{
            lastStyle = YZMoviePlayerControlsStyleNone;
        }
        
        _style = style;
        
        [self initParam];
        // 移除旧界面 添加新界面
        [self resetViews];
        [self setupConfigAndUI];
        
        if (_style != YZMoviePlayerControlsStyleNone) {
            [self setDurationSliderMaxMinValues];
            [self monitorMoviePlayback]; //resume values
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                if (lastStyle) {
                    //put style back to default
                    _style = lastStyle;
                }
            });
        } else {
            if (lastStyle) {
                //put style back to default
                _style = lastStyle;
            }
        }
    }
}



@end

# pragma mark - YZMoviePlayerControlsBar

@implementation YZMoviePlayerControlsBar

-(void)setAlpha:(CGFloat)alpha{
    
    [super setAlpha:alpha];
}
- (id)init {
    if ( self = [super init] ) {
        self.opaque = NO;
    }
    return self;
}

- (void)setColor:(UIColor *)color {
    if (_color != color) {
        _color = color;
        self.backgroundColor = _color;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    //不作为第一响应者 使得接触事件可以传递到 QNPlayView上面 返回按钮可点
    if (view == self) {
        return nil;
    }
    return view;
}


@end

