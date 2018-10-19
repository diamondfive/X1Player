//
//  TestViewController.m
//  X1PlayerSDK
//
//  Created by 彦彰 on 2017/10/20.
//  Copyright © 2017年 channelsoft. All rights reserved.
//

#import "TestViewController.h"
#import "X1PlayerView.h"


@interface TestViewController ()<X1PlayerViewDelegate>

@property (nonatomic, strong) X1PlayerView *playerView;

@property (nonatomic, strong) X1PlayerView *playerView2;

@property (nonatomic, assign) BOOL stateBarHide;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    self.view.backgroundColor = [UIColor whiteColor];
    
    //返回按钮
    UIButton *btn =[UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_videoPlayer_fanhui")] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(navBackBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [btn sizeToFit];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    
    if (self.type == 1) { //直播
        self.navigationController.navigationBar.hidden = YES;
        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 0, 375, 375*9/16)];
        self.playerView.delegate = self;

        [self.view addSubview:self.playerView];
        //http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8
        //http://live.butel.com/8bd.flv
        //http://alsource.pull.inke.cn/live/1528201103589794.flv
        [self.playerView playWithUrl:@"http://ivi.bupt.edu.cn/hls/cctv1hd.m3u8" playerTitle:@"直播测试标题" coverImage:self.image  autoPlay:NO style:YZMoviePlayerControlsStyleLive];
//        [self.playerView setBarGradientColor:[UIColor blueColor]];
        self.playerView.isNeedShowBackBtn = YES;
        
    }else if (self.type == 2){ //录播
        self.navigationController.navigationBar.hidden = NO;
        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 200, 375, 375*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        //http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4
        //http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4
        //http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:NO style:YZMoviePlayerControlsStyleDefault];
//        [self.playerView setBarGradientColor:[UIColor redColor]];
//        self.playerView.isNeedShowBackBtn = YES;

        
    }else if (self.type == 3){ //距离直播开始XX
        self.navigationController.navigationBar.hidden = NO;

        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 200, 375, 375*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        
        [self.playerView playWithUrl:@"http://live.butel.com/8bb.flv" playerTitle:@"未开播" coverImage:self.image  autoPlay:YES style:YZMoviePlayerControlsStyleLive];
        
        [self.playerView showNoStartViewWithIsLive:YES startTime:[[NSDate date] timeIntervalSince1970]+20000];
    }else if (self.type == 4){//当前页面播放续集
        self.navigationController.navigationBar.hidden = NO;

        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 200, 375, 375*9/16)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        //http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4
        //http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4
        //http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"  playerTitle:@"直播测试标题" coverImage:self.image autoPlay:NO style:YZMoviePlayerControlsStyleDefault];
        
        UIButton *btn =[UIButton buttonWithType:UIButtonTypeCustom];
        btn.backgroundColor =[UIColor redColor];
        btn.frame = CGRectMake(self.view.frame.size.width/2 - 100/2, 450, 100, 20);
        [btn setTitle:@"播放续集" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(clickNextVideoBtn:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];

        
    }else if (self.type == 5){ //进来就是小窗样式
        
        
        self.playerView =[[X1PlayerView alloc] initWithFrame:CGRectMake(0, 100, 160, 90)];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
        [self.playerView playWithUrl:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleFloatView];
        
        [self.playerView showFloatViewWithFrame:CGRectMake(0, 100, 160, 90) showCloseBtn:YES];
        
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];

}
-(void)clickBtn1:(UIButton *)sender{
    
//    
//    [self.playerView showSmallViewWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-160, 300, 160, 90)];
//    
    [self.playerView showFloatViewWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width-160, 300, 160, 90) showCloseBtn:YES];
}


-(void)clickBtn2:(UIButton *)sender{

    [self.playerView showOriginalViewWhileSlideUpPage];
    
}


-(void)clickNextVideoBtn:(UIButton *)sender{
    
          [self.playerView playWithUrl:@"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4" playerTitle:@"直播测试标题" coverImage:self.image autoPlay:YES style:YZMoviePlayerControlsStyleDefault];
    
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    
   
}

- (BOOL)prefersStatusBarHidden {
    
    return NO;
    
}


-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark --导航栏返回按钮被点击
-(void)navBackBtnClick:(UIButton *)sender{
    
    [self.playerView showFloatViewWithFrame:CGRectMake(0, 300, 160, 90) showCloseBtn:YES];
    
    [self.navigationController popViewControllerAnimated:YES];  //退出当前控制器
    
    
}

#pragma mark - 屏幕旋转
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
        
    //播放器旋转
    
    [self.playerView rorateToInterfaceOrientation:toInterfaceOrientation animated:YES];
}
#pragma mark  --支持哪些转屏方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
//    //未开播展示倒计时的时候只能竖屏
//    if (!self.playerView.isLive && self.playerView.startTimeInterval > 0) {
//        return UIInterfaceOrientationMaskPortrait;
//    }
    return UIInterfaceOrientationMaskAllButUpsideDown;
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



-(void)dealloc{

    NSLog(@"控制器销毁了");
}
@end
