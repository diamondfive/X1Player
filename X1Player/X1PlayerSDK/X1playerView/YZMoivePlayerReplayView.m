//
//  YZMoivePlayerReplayView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/18.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoivePlayerReplayView.h"
#import "YZColorUtil.h"
#import "YZMoviePlayerController.h"
#import "X1PlayerView.h"


#define QNStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

@implementation YZMoivePlayerReplayView

#pragma mark -- Lifecycle
-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
       
        [self initUI];
        [self registerNotification];

    }
    
    return self;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.backBtn.frame = CGRectMake(10, 10+QNStateBarHeight, 20, 20);
    
    self.replayBtn.frame = CGRectMake((self.frame.size.width-30)/2, (self.frame.size.height-45)/2, 30, 45);
//    self.replayLabel.frame = CGRectMake(self.replayBtn.frame.origin.x, self.replayBtn.frame.origin.y+44+5, 44, 20);
    
    self.floatViewCloseBtn.frame = CGRectMake(self.frame.size.width -30, 0, 30, 30);
    
    
}
#pragma mark setter && getter
-(void)setIsNeedShowBackBtn:(BOOL)isNeedShowBackBtn{
    
    _isNeedShowBackBtn = isNeedShowBackBtn;

}


#pragma mark -- Internal Method

-(void)initUI{
    
    self.backgroundColor = [UIColor colorWithRed:0/255 green:0/255 blue:0/255 alpha:0.7];
    
    self.backBtn =[[YZMoviePlayerControlButton alloc] init];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateNormal];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateHighlighted];
    [self.backBtn addTarget:self action:@selector(qnReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.backBtn];
    
    
   
    
    //重播按钮
    _replayBtn = [[YZMoviePlayerControlButton alloc] init];
    [_replayBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_repeat_video")] forState:UIControlStateNormal];
    [_replayBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_repeat_video")] forState:UIControlStateHighlighted];
    [_replayBtn addTarget:self action:@selector(qnReplayViewClickReplayBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_replayBtn];
    
//    // 重播按钮
//    _replayLabel = [[UILabel alloc]init];
//    _replayLabel.font = [UIFont systemFontOfSize:12];
//    _replayLabel.textColor = [QNColorUtil hexStringToColor:@"#FFFFFF"];
//    _replayLabel.text = @"重播";
//    _replayLabel.textAlignment = NSTextAlignmentCenter;
//    [self addSubview:_replayLabel];

}

//展示悬浮小窗关闭按钮
-(void)showFloatViewCloseBtn:(BOOL)isNeedShow{
    
    if (isNeedShow) {
        if (self.floatViewCloseBtn) {
            [self.floatViewCloseBtn removeFromSuperview];
        }
        
        //悬浮小窗关闭按钮
        self.floatViewCloseBtn =[[YZMoviePlayerControlButton alloc] init];
        [self.floatViewCloseBtn addTarget:self action:@selector(closeFloatViewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.floatViewCloseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_chahao")] forState:UIControlStateNormal];
        [self.floatViewCloseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_chahao")] forState:UIControlStateHighlighted];
        [self addSubview:self.floatViewCloseBtn];
        
    }else{
        
        [self.floatViewCloseBtn removeFromSuperview];
    }

}


#pragma mark -- Public Method
-(void)showReplayView:(BOOL)isNeedShow backBtn:(BOOL)showBackBtn{
    
    if (isNeedShow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25f animations:^{
                self.alpha = 0.7f;
            } completion:^(BOOL finished) {
                
            }];
        });
    } else {
        self.alpha = 0.0f;
    }
    
    if (showBackBtn) {
        self.backBtn.alpha = 1;
    }else{
        self.backBtn.alpha = 0;
    }
}

#pragma mark -- Notification
-(void)registerNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillEnterFullScreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullScreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];
    
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChangeCauseControlsUIChange) name:YZMoviePlayerMediaStateChangedNotification object:nil];

}

-(void)moviePlayerWillEnterFullScreen:(NSNotification *)sender{
    
    [self.backBtn removeTarget:self action:@selector(qnReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(qnReplayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)moviePlayerWillExitFullScreen:(NSNotification *)sender{
    
    [self.backBtn removeTarget:self action:@selector(qnReplayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(qnReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
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
  
            [self showReplayView:NO backBtn:NO];//隐藏重播视图
            

            break;
        case PS_SEEKTO:
            
            break;
        case PS_LOADING:
   
            [self showReplayView:NO backBtn:NO];

            
            break;
        case PS_PAUSED:

            [self showReplayView:NO backBtn:NO];//隐藏重播视图
            
            break;
            //视频的开始和结束
        case PS_STOPED:
            if (self.moviePlayer.isCompletion) {
                
                //展示重播视图,隐藏播放视图
                if (self.moviePlayer.fullscreen) {
                    [self showReplayView:YES backBtn:YES];
                    
                }else{
                    
                    if (self.moviePlayer.controls.style == YZMoviePlayerControlsStyleFloatView) {
                        [self showReplayView:YES backBtn:NO];

                        [self showFloatViewCloseBtn:YES];

                    }else{
                        
                        [self showReplayView:YES backBtn:_isNeedShowBackBtn ?YES :NO];

                        [self showFloatViewCloseBtn:NO];
                    }
   
                    
                }
                
            }else{
                //隐藏重播视图,展示播放视图
                [self showReplayView:NO backBtn:NO];
                
            }
            
            break;
        case PS_BUFFERING:

            [self showReplayView:NO backBtn:NO];
            
            break;
        default:
            break;
    }
    
}



#pragma mark -- Action
-(void)qnReplayViewClickBackBtn:(UIButton *)sender{
    
    [self.moviePlayer backBtnPressed];

}

-(void)qnReplayViewClickFullScreenBtn:(UIButton *)sender{
    
    [self.moviePlayer clickFullScreenBtn];

}

-(void)qnReplayViewClickReplayBtn:(UIButton *)sender{
    
    [self.moviePlayer clickPlayPauseBtn];
}


-(void)closeFloatViewButtonClick:(UIButton *)sender{
    
    [self.moviePlayer closeFloatViewBtnPressed];

}



@end
