//
//  YZMoivePlayerNoStartView.h
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/21.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  封面视图，开始播放前的占位图

#import <UIKit/UIKit.h>
#import "YZMoviePlayerControlButton.h"

@class YZMoviePlayerController;

@interface YZMoviePlayerCoverView : UIView

@property (nonatomic, strong) YZMoviePlayerControlButton *backBtn;

@property (nonatomic, strong) YZMoviePlayerControlButton *fullscreenBtn;

@property (nonatomic, strong) YZMoviePlayerControlButton *playpauseBtn;
//使用流量情况下的播放按钮
@property (nonatomic, strong) UILabel *WWANPlayLabel;

@property (nonatomic, strong) UIButton *WWANPlayBtn;

@property (nonatomic, strong) UIImageView *coverImageView;


@property (nonatomic, weak) YZMoviePlayerController *moviePlayer;


-(instancetype)initWithMoviePlayer:(YZMoviePlayerController *)moviePlayer;

/**
 展示播放视图
 @param showBackBtn 返回按钮是否展示
 @param showCoverImagePlayBtn 播放暂停按钮和封面图是否展示
 */
-(void)showPlayViewWithBackBtn:(BOOL)showBackBtn coverImagePlayBtn:(BOOL)showCoverImagePlayBtn;



//设置封面
-(void)setupCoverImage:(UIImage *)image;



@end
