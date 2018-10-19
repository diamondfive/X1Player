//
//  YZRootViewController.m
//  X1PlayerSDK
//
//  Created by 彦彰 on 2017/10/10.
//  Copyright © 2017年 channelsoft. All rights reserved.
//

#import "YZRootViewController.h"
#import "TestViewController.h"


@interface YZRootViewController ()

@end

@implementation YZRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



#pragma mark - orientation
#pragma mark - 控制转屏
// 哪些页面支持自动转屏
- (BOOL)shouldAutorotate{
    
    // YZPlayViewController 控制器支持自动转屏
    if ([self.topViewController isKindOfClass:[TestViewController class]]) {
        // 调用YZBrightnessViewShared单例记录播放状态是否锁定屏幕方向
        return YES; // 未来功能
    }
    return NO;
}

// viewcontroller支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    if ([self.topViewController isKindOfClass:[TestViewController class]]) { // LMPlayViewController这个页面支持转屏方向
      
        
//            return UIInterfaceOrientationMaskAllButUpsideDown;
        return [self.topViewController supportedInterfaceOrientations];
        
    }
    // 其他页面
    return UIInterfaceOrientationMaskPortrait;
}

-(UIViewController *)childViewControllerForStatusBarStyle{
    
    return self.visibleViewController;
}


@end
