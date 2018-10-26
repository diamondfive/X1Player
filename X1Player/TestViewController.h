//
//  TestViewController.h
//  X1PlayerSDK
//
//  Created by 彦彰 on 2017/10/20.
//  Copyright © 2017年 channelsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestViewController : UIViewController

@property (nonatomic, assign) float type;// 1 直播  2 录播  3 距离开始XX

@property (nonatomic, assign) NSInteger startTime;

@property (nonatomic, strong) NSString *imageUrl;

@property (nonatomic, strong) UIImage *image;

@end
