//
//  YZMoivePlayerFloatView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/28.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoivePlayerFloatView.h"
#import "YZMoviePlayerControlButton.h"
#import "YZMoviePlayerControls.h"
#import "YZMoviePlayerController.h"
#import "X1PlayerView.h"

@implementation YZMoivePlayerFloatView

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        [self initUI];
    }
    
    return self;
    
}

-(void)initUI{
    
    //添加手势
    UITapGestureRecognizer *tap =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(floatViewClick:)];
    [self addGestureRecognizer:tap];
//    tap.cancelsTouchesInView = NO; //响应者链继续传递
    
    //悬浮小窗关闭按钮
    self.floatViewCloseBtn =[[YZMoviePlayerControlButton alloc] init];
    [self.floatViewCloseBtn addTarget:self action:@selector(closeFloatViewButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.floatViewCloseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_chahao")] forState:UIControlStateNormal];
    [self.floatViewCloseBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_chahao")] forState:UIControlStateHighlighted];
    [self addSubview:self.floatViewCloseBtn];
}

#pragma mark selector action

-(void)floatViewClick:(UITapGestureRecognizer *)sender{
    
    [self.controls floatViewClick:sender];
}

-(void)closeFloatViewButtonClick:(UIButton *)sender{
    
    [self.controls closeFloatViewButtonClick:sender];
    
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.floatViewCloseBtn.frame = CGRectMake(self.frame.size.width -30, 0, 30, 30);

}


#pragma mark -- touchEvent
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    
    if (self == [touch view]) {
        
        CGPoint location = [touch locationInView:self.controls.moviePlayer.view];
        CGPoint pLocation = [touch previousLocationInView:self.controls.moviePlayer.view];
        CGPoint movePoint = CGPointMake(location.x - pLocation.x, location.y-pLocation.y);
        CGPoint newCenter = CGPointMake(self.controls.moviePlayer.view.center.x + movePoint.x, self.controls.moviePlayer.view.center.y + movePoint.y);
        // NSLog(@"location %@",NSStringFromCGPoint(location));
        //
        // NSLog(@"pLocation %@",NSStringFromCGPoint(pLocation));
        
        //处理边界条件
        if (newCenter.x - self.controls.moviePlayer.view.frame.size.width/2< 0 ) {
            newCenter.x = self.controls.moviePlayer.view.frame.size.width/2;
        }if (newCenter.x- self.controls.moviePlayer.view.frame.size.width/2 >[UIScreen mainScreen].bounds.size.width - self.controls.moviePlayer.view.frame.size.width){
            
            newCenter.x = [UIScreen mainScreen].bounds.size.width - self.controls.moviePlayer.view.frame.size.width + self.controls.moviePlayer.view.frame.size.width/2;
        } if (newCenter.y- self.controls.moviePlayer.view.frame.size.height/2 < 0){
            
            newCenter.y =  self.controls.moviePlayer.view.frame.size.height/2;
            
        }if (newCenter.y- self.controls.moviePlayer.view.frame.size.height/2 >[UIScreen mainScreen].bounds.size.height - self.controls.moviePlayer.view.frame.size.height){
            
            newCenter.y = [UIScreen mainScreen].bounds.size.height - self.controls.moviePlayer.view.frame.size.height + self.controls.moviePlayer.view.frame.size.height/2;
        }
        
        self.controls.moviePlayer.view.center = newCenter;
        
    }
    
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [super touchesEnded:touches withEvent:event];
}


@end
