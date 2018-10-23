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

#define QNStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height


@interface YZMoivePlayerCoverView ()

//防止返回按钮和底色重合
@property (nonatomic, strong) CALayer *maskLayer;

@end

@implementation YZMoivePlayerCoverView

#pragma mark -- lifecycle
-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        
        [self initUI];
        [self registerNotification];
    }
    return self;
}

-(void)layoutSubviews{
    
    self.coverImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    self.maskLayer.frame = self.coverImageView.bounds;
    
    
    self.backBtn.frame = CGRectMake(10, 10+QNStateBarHeight, 20, 20);
    
    
    
    self.playpauseBtn.frame = CGRectMake(self.bounds.size.width/2 - 38/2, self.bounds.size.height/2 - 38/2, 38, 38);
    
    self.fullscreenBtn.frame = CGRectMake(self.frame.size.width-20-15, self.frame.size.height-20-15, 20, 20);
    
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

#pragma mark -- Internal Method

-(void)initUI{
    
    self.backgroundColor = [UIColor clearColor];
    
    self.coverImageView =[[UIImageView alloc] init];
    
    self.maskLayer = [[CALayer alloc] init];
    self.maskLayer.backgroundColor =[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
    [self.coverImageView.layer addSublayer:self.maskLayer];
    
    [self addSubview:self.coverImageView];

    self.backBtn =[[YZMoviePlayerControlButton alloc] init];
    self.backBtn.showsTouchWhenHighlighted = YES;
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateNormal];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateHighlighted];
    [self.backBtn addTarget:self action:@selector(qnPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.backBtn];
    

    self.playpauseBtn = [[YZMoviePlayerControlButton alloc] init];
    self.playpauseBtn.showsTouchWhenHighlighted = YES;
    [self.playpauseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_bigplay_nor")] forState:UIControlStateNormal];
    [self.playpauseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_bigplay_nor")] forState:UIControlStateHighlighted];
    [self.playpauseBtn addTarget:self action:@selector(qnPlayViewClickPlayPauseBtn:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.playpauseBtn];
    
//
//    self.fullscreenBtn = [[QNButton alloc] init];
//    self.fullscreenBtn.showsTouchWhenHighlighted = YES;
//    [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateNormal];
//    [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateHighlighted];
//    [self.fullscreenBtn addTarget:self action:@selector(qnPlayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
//
//    [self addSubview:self.fullscreenBtn];
    

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
    }else{
        self.coverImageView.alpha = 0;
        self.playpauseBtn.alpha = 0;
        
    }
    
}

#pragma mark --- Notification



-(void)registerNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillEnterFullScreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullScreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];
    
    
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangeCauseControlsUIChange) name:YZMoviePlayerMediaStateChangedNotification object:nil];
}


-(void)moviePlayerWillEnterFullScreen:(NSNotification *)sender{
    
//    [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateNormal];
//     [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_reduce_nor")] forState:UIControlStateHighlighted];
    [self.backBtn removeTarget:self action:@selector(qnPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(qnPlayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)moviePlayerWillExitFullScreen:(NSNotification *)sender{
//
//    [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateNormal];
//    [self.fullscreenBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_screen_full_nor")] forState:UIControlStateHighlighted];

    
    
    [self.backBtn removeTarget:self action:@selector(qnPlayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(qnPlayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];

}

// !!!:播放状态改变时的回调(全屏旋转也触发此回调，因为涉及UI的显示隐藏)
- (void)stateChangeCauseControlsUIChange
{
    int state = [self.moviePlayer getPlaybackState];
    NSLog(@"QNYZMovieControls stateChangeCauseControlsUIChange = %d", state);
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
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn ?YES :NO coverImagePlayBtn:NO];
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
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn ?YES :NO coverImagePlayBtn:NO];
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
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn ?YES :NO coverImagePlayBtn:NO];
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
                        
                        [self showPlayViewWithBackBtn:_isNeedShowBackBtn ?YES :NO coverImagePlayBtn:YES];
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
                    
                    [self showPlayViewWithBackBtn:_isNeedShowBackBtn ?YES :NO coverImagePlayBtn:NO];
                }
                
            }
          
            
            break;
        default:
            break;
    }
    
}



#pragma  mark --  btn action
-(void)qnPlayViewClickBackBtn:(UIButton *)sender{
    
    [self.moviePlayer clickBackBtn];
}

-(void)qnPlayViewClickPlayPauseBtn:(UIButton *)sender{
    
    [self removeFromSuperview];
    
    [self.moviePlayer clickPlayPauseBtn];
}

-(void)qnPlayViewClickFullScreenBtn:(UIButton *)sender{
    
    [self.moviePlayer clickFullScreenBtn];
}



@end
