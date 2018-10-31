//
//  YZMoivePlayerReplayView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/18.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoivePlayerReplayView.h"
#import "YZMoviePlayerController.h"
#import "X1PlayerView.h"


#define YZStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height

@implementation YZMoivePlayerReplayView

#pragma mark -- Lifecycle
-(instancetype)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer{
    if (self = [super init]) {
       
        self.moviePlayer = moviePlayer;
        
        [self initUI];
        [self registerNotification];

    }
    
    return self;
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.backBtn.frame = CGRectMake(10, 20, 20, 20);
    
    self.replayBtn.frame = CGRectMake((self.frame.size.width-32)/2, (self.frame.size.height-48)/2- 8, 32, 48);
    self.replayLabel.frame = CGRectMake((self.frame.size.width-40)/2, self.replayBtn.frame.origin.y+40, 40, 20);
    
    self.floatViewCloseBtn.frame = CGRectMake(self.frame.size.width -30, 0, 30, 30);
    
    
}


#pragma mark -- Internal Method

-(void)initUI{
    
    self.backgroundColor = [UIColor colorWithRed:0/255 green:0/255 blue:0/255 alpha:0.7];
    
    self.backBtn =[[YZMoviePlayerControlButton alloc] init];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateNormal];
    [self.backBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_movie_back_nor")] forState:UIControlStateHighlighted];
    [self.backBtn addTarget:self action:@selector(yzReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:self.backBtn];
    
    
   
    
    //重播按钮
    _replayBtn = [[YZMoviePlayerControlButton alloc] init];
    [_replayBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_repeat_video")] forState:UIControlStateNormal];
    [_replayBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_repeat_video")] forState:UIControlStateHighlighted];
    [_replayBtn addTarget:self action:@selector(yzReplayViewClickReplayBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_replayBtn];
    
    // 重播按钮
    _replayLabel = [[UILabel alloc]init];
    _replayLabel.font = [UIFont systemFontOfSize:14];
    _replayLabel.textColor = [UIColor whiteColor];
    _replayLabel.text = @"重播";
    _replayLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_replayLabel];

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
-(void)showReplayViewWithBackBtn:(BOOL)isNeedShow{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25f animations:^{
            self.alpha = 1.0f;
        } completion:^(BOOL finished) {
            
        }];
    });
    
    if (isNeedShow) {
        self.backBtn.alpha = 1;
    }else{
        self.backBtn.alpha = 0;
    }
}

#pragma mark -- Notification
-(void)registerNotification{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillEnterFullScreen:) name:YZMoviePlayerWillEnterFullscreenNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullScreen:) name:YZMoviePlayerWillExitFullscreenNotification object:nil];


}

-(void)moviePlayerWillEnterFullScreen:(NSNotification *)sender{
    
    [self.backBtn removeTarget:self action:@selector(yzReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(yzReplayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)moviePlayerWillExitFullScreen:(NSNotification *)sender{
    
    [self.backBtn removeTarget:self action:@selector(yzReplayViewClickFullScreenBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.backBtn addTarget:self action:@selector(yzReplayViewClickBackBtn:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark -- Action
-(void)yzReplayViewClickBackBtn:(UIButton *)sender{
    
    [self.moviePlayer clickBackBtn];

}

-(void)yzReplayViewClickFullScreenBtn:(UIButton *)sender{
    
    [self.moviePlayer clickFullScreenBtn];

}

-(void)yzReplayViewClickReplayBtn:(UIButton *)sender{
    [self removeFromSuperview];

    [self.moviePlayer clickPlayPauseBtn];
}


-(void)closeFloatViewButtonClick:(UIButton *)sender{
    
    [self.moviePlayer clickCloseFloatViewBtn];

}



@end
