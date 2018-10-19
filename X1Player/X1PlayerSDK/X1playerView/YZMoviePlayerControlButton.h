//
//  YZButton.h
//  YZMoviePlayerController
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol YZButtonDelegate <NSObject>
@optional
- (void)buttonTouchedDown:(UIButton *)button;
- (void)buttonTouchedUpOutside:(UIButton *)button;
- (void)buttonTouchCancelled:(UIButton *)button;
@end

@interface YZMoviePlayerControlButton : UIButton

@property (nonatomic, weak) id<YZButtonDelegate> delegate;

@end
