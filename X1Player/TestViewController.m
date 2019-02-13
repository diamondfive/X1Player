//
//  TestViewController.m
//  X1PlayerSDK
//
//  Created by 彦彰 on 2017/10/20.
//  Copyright © 2017年 channelsoft. All rights reserved.
//

#import "TestViewController.h"
#import "X1PlayerView.h"

//判断是否是iPhone X/XS/XR/XS Max
static inline BOOL IPhoneXSeries() {
    BOOL iPhoneXSeries = NO;
    if (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {
        return iPhoneXSeries;
    }
    
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    
    return iPhoneXSeries;
}

#define YZStateBarHeight [[UIApplication sharedApplication] statusBarFrame].size.height
#define YZSCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define YZSCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height


@interface TestViewController ()<X1PlayerViewDelegate>

@property (nonatomic, strong) X1PlayerView *playerView;

@property (nonatomic, strong) X1PlayerView *playerView2;

@property (nonatomic, assign) BOOL stateBarHide;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    [self registerNotification];
    //返回按钮
    UIButton *btn =[UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_fanhui")] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(navBackBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [btn sizeToFit];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    
    if (self.type == 1) { //直播
        self.navigationController.navigationBar.hidden = YES;
        
        if (IPhoneXSeries()) {
              self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, YZStateBarHeight, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }else{
            
              self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 0, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }
      
        self.playerView.delegate = self;

        [self.view addSubview:self.playerView];
        
        self.playerView.isNeedShowBackBtn = YES;
        [self.playerView playWithUrl:@"http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8" playerTitle:@"直播测试标题" coverImage:self.image  autoPlay:NO style:YZMoviePlayerControlsStyleLive];
//        [self.playerView setBarGradientColor:[UIColor blueColor]];
        
    }else if (self.type == 1.1f){//直播多清晰度
        self.navigationController.navigationBar.hidden = YES;
        
        //清晰度模型数组
        YZMutipleDefinitionModel *model1 = [[YZMutipleDefinitionModel alloc] init];
        model1.title = @"超清";
        model1.url = @"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4.flv";

        YZMutipleDefinitionModel *model2 = [[YZMutipleDefinitionModel alloc] init];
        model2.title = @"高清";
        model2.url = @"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv";
        
        YZMutipleDefinitionModel *model3 =[[YZMutipleDefinitionModel alloc] init];
        model3.title = @"标清";
        model3.url = @"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_550.flv";
        
        if (IPhoneXSeries()) {
            self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, YZStateBarHeight, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }else{
            
            self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 0, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        
        self.playerView.isNeedShowBackBtn =YES;

        [self.playerView playWithUrl:@"http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv" definitionUrlArr:@[model1,model2,model3] playerTitle:@"直播清晰度切换测试" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleLive];
        
        
    }
    
    else if (self.type == 2){ //录播
        self.navigationController.navigationBar.hidden = YES;
        
        if (IPhoneXSeries()) {
            self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, YZStateBarHeight, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }else{
            
            self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 0, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        }
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleDefault];

        self.playerView.isNeedShowBackBtn = YES;
        
    }
    else if (self.type == 2.1f){//录播多清晰度
        
        self.navigationController.navigationBar.hidden = NO;
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        CGFloat topLength = 0;
        if (@available(iOS 11.0, *)) {
            
            topLength = mainWindow.safeAreaInsets.top+44;
        }else{
            
            topLength = mainWindow.rootViewController.topLayoutGuide.length+44;
            
        }
        
        //清晰度模型数组
        YZMutipleDefinitionModel *model1 = [[YZMutipleDefinitionModel alloc] init];
        model1.title = @"超清";
        model1.url = @"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f30.mp4";
        
        YZMutipleDefinitionModel *model2 = [[YZMutipleDefinitionModel alloc] init];
        model2.title = @"标清";
        model2.url = @"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f20.mp4";
        
        YZMutipleDefinitionModel *model3 =[[YZMutipleDefinitionModel alloc] init];
        model3.title = @"流畅";
        model3.url = @"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4";
        
        
        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, topLength, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        
        self.playerView.isNeedShowBackBtn =NO;
        
        [self.playerView playWithUrl:@"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/e1ab85305285890781763144364/v.f10.mp4" definitionUrlArr:@[model1,model2,model3] playerTitle:@"录播清晰度切换测试" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleDefault];
        
        
    }
    
    else if (self.type == 3){ //距离直播开始XX
        self.navigationController.navigationBar.hidden = NO;

        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 200, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        
        [self.playerView playWithUrl:@"http://live.butel.com/8bb.flv" playerTitle:@"未开播" coverImage:self.image  autoPlay:YES style:YZMoviePlayerControlsStyleLive];
        
        [self.playerView showCountdownViewWithIsLive:YES startTime:[[NSDate date] timeIntervalSince1970]+20000];
    }else if (self.type == 4){//当前页面播放续集
        self.navigationController.navigationBar.hidden = NO;

        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 200, YZSCREEN_WIDTH, YZSCREEN_WIDTH*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];

        self.playerView.isShowWWANViewInAutoPlay = NO;
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"  playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleDefault];
        
        UIButton *btn =[UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor =[UIColor redColor];
        btn.frame = CGRectMake(self.view.frame.size.width/2 - 100/2, 450, 100, 20);
        [btn setTitle:@"播放续集" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clickBtn4:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];

        
    }else if (self.type == 5){ //进来就是小窗样式
        
        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 100, 160, 90)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleFloatView];
        
        [self.playerView showFloatViewWithFrame:CGRectMake(0, 100, 160, 90) showCloseBtn:YES];
        
    }
}



-(void)clickBtn4:(UIButton *)sender{
    
      [self.playerView playWithUrl:@"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleDefault];
    

}

#pragma mark --导航栏返回按钮被点击
-(void)navBackBtnClick:(UIButton *)sender{
    
    [self.playerView showFloatViewWithFrame:CGRectMake(0, 300, 160, 90) showCloseBtn:YES];
    
    [self.navigationController popViewControllerAnimated:YES];  //退出当前控制器
    
    
}

#pragma mark -- Notification
-(void)registerNotification{
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(x1playerLockedNotification) name:X1PlayerViewOnClickLockScreenBtnNotification object:nil];
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(x1playerUnLockedNotification) name:X1PlayerViewOnClickUnLockScreenBtnNotification object:nil];

}

//-(void)x1playerLockedNotification{
//
//    [self shouldAutorotate];
//}
//
//-(void)x1playerUnLockedNotification{
//
//    [self shouldAutorotate];
//}

#pragma mark - 屏幕旋转
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    NSLog(@"toInterfaceOrientation%ld",(long)toInterfaceOrientation);
}

#pragma mark  --支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {

    return UIInterfaceOrientationMaskAllButUpsideDown;
}

-(BOOL)shouldAutorotate{
    if (self.playerView.isLocked) {
        return NO;
    }else{
        
        return YES;
    }
}


#pragma mark -- X1PlayerViewDelegate


//点击小窗的回调
-(void)x1PlayerViewOnClickFloatView:(X1PlayerView *)x1PlayerView{
    
    
}
//点击小窗关闭按钮的回调
-(void)x1PlayerViewOnClickCloseFloatViewBtn:(X1PlayerView *)x1PlayerView{
    
    
}
//点击竖屏返回按钮的回调
-(void)x1PlayerViewOnClickBackBtn:(X1PlayerView *)x1PlayerView{
    
    [self navBackBtnClick:nil];
}


//将要进入全屏
-(void)x1PlayerViewOnWillEnterFullScreen:(X1PlayerView *)x1PlayerView{
    
    
}
//将要退出全屏
-(void)x1PlayerViewOnWillExitFullScreen:(X1PlayerView *)x1PlayerView{
    
    
}

//播放完成回调
-(void)x1PlayerViewOnPlayComplete:(X1PlayerView *)x1PlayerView{
//    //展示重播视图
//    [self.playerView showReplayView];
}


-(void)dealloc{

    NSLog(@"TestViewController控制器销毁了");
}
@end
