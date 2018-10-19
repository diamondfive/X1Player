//
//  YZButton.m
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoviePlayerControlButton.h"

static const CGFloat expandedMargin = 10.f;

@implementation YZMoviePlayerControlButton

- (id)init {
    if ( self = [super init] ) {
         self.showsTouchWhenHighlighted = YES;
//        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self addTarget:self action:@selector(touchedDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchedUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(touchCancelled:) forControlEvents:UIControlEventTouchCancel];
    }
    return self;
}

- (void)touchedDown:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(buttonTouchedDown:)]) {
        [self.delegate buttonTouchedDown:self];
    }
}

- (void)touchedUpOutside:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(buttonTouchedUpOutside:)]) {
        [self.delegate buttonTouchedUpOutside:self];
    }
}

- (void)touchCancelled:(UIButton *)button {
    if ([self.delegate respondsToSelector:@selector(buttonTouchCancelled:)]) {
        [self.delegate buttonTouchCancelled:self];
    }
}

//点击区域扩充
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect expandedFrame = CGRectMake(0 - expandedMargin , 0 - expandedMargin , self.frame.size.width + (expandedMargin * 2) , self.frame.size.height + (expandedMargin * 2));
    
    if ((CGRectContainsPoint(expandedFrame, point) == 1) && self.alpha > 0.01) {
        return self;
    }else{
        
        return nil;
    }
    
}

@end
