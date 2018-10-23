//
//  YZMoivePlayerNoStartView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/21.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoivePlayerCoverView.h"
#import "YZMoviePlayerController.h"
#import "X1PlayerView.h"

#define YZStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height


@interface YZMoivePlayerCoverView ()

//封面图片遮罩
@property (nonatomic, strong) CALayer *coverImageViewMaskLayer;
//防止视频底色与返回按钮底色一致导致返回按钮不可见
@property (nonatomic, strong) CALayer *backBtnMaskLayer;



@end

@implementation YZMoivePlayerCoverView

#pragma mark -- lifecycle
-(instancetype)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer{
    
    if (self = [super init]) {
        self.moviePlayer = moviePlayer;
        [self initUI];
        [self registerNotification];
    }
    return self;
}

-(void)willMoveToSuperview:(UIView *)newSuperview{
    
    if (newSuperview == nil) {
        
        NSLog(@"xxx");
    }
    
}

-(void)layoutSubviews{
    
    self.coverImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.coverImageViewMaskLayer.frame = self.coverImageView.bounds;
    
    
    self.backBtn.frame = CGRectMake(10, 5+YZStateBarHeight, 20, 20);
    self.backBtnMaskLayer.frame = self.backBtn.bounds;
    
    
    self.playpauseBtn.frame = CGRectMake(self.bounds.size.width/2 - 38/2, self.bounds.size.height/2 - 38/2, 38, 38);
    
    self.WWANPlayLabel.frame = CGRectMake(10, self.bounds.size.height/2-30, self.bounds.size.width-20, 20);
    
    self.WWANPlayBtn.frame = CGRectMake(self.bounds.size.width/2 - 40, self.bounds.size.height/2 , 80, 30);
 
    
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    //不作为第一响应者 使得接触事件可以传递下去 control可以响应
    if (view == self) {
        return nil;
    }
    return view;
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark -- Internal Method

-(void)initUI{
    
    self.backgroundColor = [UIColor clearColor];
    
    self.coverImageView =[[UIImageView alloc] init];
    
    self.coverImageViewMaskLayer = [[CALayer alloc] init];
    self.coverImageViewMaskLayer.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
    [self.coverImageView.layer addSublayer:self.coverImageViewMaskLayer];
    
    [self addSubview:self.coverImageView];
    

    self.backBtn =[[YZMoviePlayerControlButton alloc] init];
    
    self.backBtnMaskLayer = [[CALayer alloc] init];
    self.backBtnMaskLayer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1].CGColor;
    [self.backBtn.layer addSublayer:self.backBtnMaskLayer];
    
    self.backBtn.showsTouchWhenHighlighted = YES;
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateNormal];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateHighlighted];
    [self.backBtn addTarget:self action:@selector(yzPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backBtn];
    

    if (self.moviePlayer.fatherView.networkMonitor.currentReachabilityStatus == ReachableViaWWAN) {
        
        self.WWANPlayLabel =[[UILabel alloc] init];
        self.WWANPlayLabel.text = @"正在使用非WIFI网络,播放将产生流量费用";
        self.WWANPlayLabel.textAlignment = NSTextAlignmentCenter;
        self.WWANPlayLabel.font =[UIFont systemFontOfSize:15];
        self.WWANPlayLabel.textColor = [UIColor whiteColor];
        [self addSubview:self.WWANPlayLabel];
        
        self.WWANPlayBtn=[UIButton buttonWithType:UIButtonTypeCustom];
        self.WWANPlayBtn.layer.cornerRadius = 4;
        self.WWANPlayBtn.layer.masksToBounds = YES;
        self.WWANPlayBtn.backgroundColor = YZColorFromRGB(0x3e9adf);
        [self.WWANPlayBtn setTitle:@"继续播放" forState:UIControlStateNormal];
        [self.WWANPlayBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.WWANPlayBtn.titleLabel.font = [UIFont systemFontOfSize:15];
        
        [self.WWANPlayBtn addTarget:self action:@selector(yzPlayViewClickPlayPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.WWANPlayBtn];
        
    }else{
        
        self.playpauseBtn = [[YZMoviePlayerControlButton alloc] init];
        self.playpauseBtn.showsTouchWhenHighlighted = YES;
        [self.playpauseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_bigplay_nor")] forState:UIControlStateNormal];
        [self.playpauseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_bigplay_nor")] forState:UIControlStateHighlighted];
        [self.playpauseBtn addTarget:self action:@selector(yzPlayViewClickPlayPauseBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.playpauseBtn];
        
    }


    

}

#pragma mark -- Public Method
//展示播放视图
-(void)showPlayViewWithBackBtn:(BOOL)showBackBtn coverImagePlayBtn:(BOOL)showCoverImagePlayBtn{
    if (showBackBtn) {
        self.backBtn.alpha = 1;
        
    }else{
        self.backBtn.alpha = 0;
    }
    
    if (showCoverImagePlayBtn) {
        self.coverImageView.alpha = 1;
        self.playpauseBtn.alpha = 1;
        self.WWANPlayBtn.alpha = 1;
        self.WWANPlayLabel.alpha = 1;
        
    }else{
        self.coverImageView.alpha = 0;
        self.playpauseBtn.alpha = 0;
        self.WWANPlayBtn.alpha = 0;
        self.WWANPlayLabel.alpha = 0;
        
    }
    
}

#pragma mark --- Notification
-(void)registerNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillEnterFullScreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullScreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];
    
    
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangeCauseControlsUIChange) name:YZMoviePlayerMediaStateChangedNotification object:nil];
}


-(void)moviePlayerWillEnterFullScreen:(NSNotification *)sender{
    

    [self.backBtn removeTarget:self action:@selector(yzPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(yzPlayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    

    
}
-(void)moviePlayerWillExitFullScreen:(NSNotification *)sender{

    
    [self.backBtn removeTarget:self action:@selector(yzPlayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(yzPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];

}

// !!!:播放状态改变时的回调(全屏旋转也触发此回调，因为涉及UI的显示隐藏)
- (void)stateChangeCauseControlsUIChange
{
    int state = [self.moviePlayer getPlaybackState];
    NSLog(@"yzYZMovieControls stateChangeCauseControlsUIChange = %d", state);
    switch (state) {
        case PS_NONE:

            break;
        case PS_PLAYING:
            if (self.moviePlayer.isFullscreen) {
                
                [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
            }else{
                
                if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                     [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                }else{
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn coverImagePlayBtn:NO];
                }
                
            }

            break;
        case PS_SEEKTO:
            
            break;
        case PS_LOADING:
            if (self.moviePlayer.fullscreen) {
                [self showPlayViewWithBackBtn:YES coverImagePlayBtn:NO];
            }else{
                
                if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                    [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                }else{
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn coverImagePlayBtn:NO];
                }
                
                
            }
  
            break;
        case PS_PAUSED:
    
            
            if (self.moviePlayer.fullscreen) {
                [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
            }else{
                
                if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                    [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                }else{
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn coverImagePlayBtn:NO];
                }
                
            }


            break;
            //视频的开始和结束
        case PS_STOPED:
        
            
            if (self.moviePlayer.isCompletion) {
                
                [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                
            }else{
                

                if (self.moviePlayer.fullscreen) {
                    [self showPlayViewWithBackBtn:YES coverImagePlayBtn:YES];
                    
                }else{
                    
                    if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                        [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                    }else{
                        
                        [self showPlayViewWithBackBtn:_isNeedShowBackBtn coverImagePlayBtn:YES];
                    }
                    
                }
                
            }
            
            break;
        case PS_BUFFERING:
            
            if (self.moviePlayer.fullscreen) {
                [self showPlayViewWithBackBtn:YES coverImagePlayBtn:NO];
            }else{
                
                if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                    [self showPlayViewWithBackBtn:NO coverImagePlayBtn:NO];
                }else{
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn coverImagePlayBtn:NO];
                }
                
            }
          
            
            break;
        default:
            break;
    }
    
}



#pragma  mark --  btn action
-(void)yzPlayViewClickBackBtn:(UIButton *)sender{
    
    [self.moviePlayer clickBackBtn];
}

-(void)yzPlayViewClickPlayPauseBtn:(UIButton *)sender{
    
    [self.moviePlayer clickPlayPauseBtn];
}

-(void)yzPlayViewClickFullScreenBtn:(UIButton *)sender{
    
    [self.moviePlayer clickFullScreenBtn];
}




#pragma mark setter && getter
-(void)setIsNeedShowBackBtn:(BOOL)isNeedShowBackBtn{
    _isNeedShowBackBtn = isNeedShowBackBtn;
    
}


-(void)setupCoverImage:(UIImage *)image{
    
    if (!image) {
        return;
    }
    
    [self.coverImageView setImage:image];
    
}


@end
