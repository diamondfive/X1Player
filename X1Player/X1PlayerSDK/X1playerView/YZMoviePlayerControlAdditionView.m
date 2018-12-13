//
//  YZMoviePlayerControlAdditionView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  

#import "YZMoviePlayerControlAdditionView.h"
#import "YZMoviePlayerControls.h"
#import "YZMoviePlayerControlButton.h"
#import "YZMoviePlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "YZMoviePlayerBrightnessView.h"
#import "X1PlayerView.h"
#import "YZMoviePlayerControlButton.h"

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface YZMoviePlayerControlAdditionView()<UIGestureRecognizerDelegate,UITableViewDelegate,UITableViewDataSource>

/**快进快退视图*/
@property (nonatomic, strong)UIView *fastForwardView;

@property (nonatomic, strong)UIImageView *fastForwardImgView;

@property (nonatomic, strong)UILabel *fastForwardLabel;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection panDirection;

/** 是否是快进 */
@property (nonatomic, assign) BOOL isForward;

/** 声音滑杆 */
@property (nonatomic, strong) UISlider *volumeViewSlider;



@end


@implementation YZMoviePlayerControlAdditionView


#pragma mark -- Lifecycle
- (instancetype)initWithFrame:(CGRect)frame{
    
    if (self =[super initWithFrame:frame]) {
        
        [self initUI];
        
        [self configureVolume];
        
        [self createGesture];
   
        [self createFastForwardView];
        
        
        [YZMoviePlayerBrightnessView sharedBrightnessView];
    }
    
    return self;
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    self.fastForwardView.frame =CGRectMake((self.frame.size.width -120)/2, (self.frame.size.height - 80)/2, 120, 80);
    
    self.fastForwardImgView.frame = CGRectMake((self.fastForwardView.frame.size.width - 50)/2, 0, 50, 50);
    
    self.fastForwardLabel.frame = CGRectMake(0, self.fastForwardView.frame.size.height-20-10, self.fastForwardView.frame.size.width, 20);
    
    self.lockBtn.frame = CGRectMake(30, self.frame.size.height/2 - 15, 30, 30);
}

#pragma mark -- Internal Method

-(void)initUI{
    
    self.lockBtn =[[YZMoviePlayerControlButton alloc] init];
    
    [self.lockBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_moive_unlock")] forState:UIControlStateNormal];
    [self.lockBtn setImage:[UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_moive_lock")] forState:UIControlStateSelected];
    [self.lockBtn addTarget:self action:@selector(clickLockBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:self.lockBtn];

}


#pragma mark - 系统音量相关
/**
 *  获取系统音量
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

/**
 *  改变音量
 */
- (void)changeVolume:(CGFloat)value {
    self.volumeViewSlider.value -= value / 10000;
}

/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 耳机拔掉
            // 拔掉耳机继续播放
            [self.controls.moviePlayer play];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
            // called at start - also when other audio wants to play
            NSLog(@"AVAudioSessionRouteChangeReasonCategoryChange");
            break;
    }
}

#pragma mark - 快进快退相关
/**
 创建快进快退视图
 */
-(void)createFastForwardView{
    
    if (_fastForwardView) {
        [_fastForwardView removeFromSuperview];
        
    }
    
    _fastForwardView                     = [[UIView alloc] init];
    _fastForwardView.backgroundColor     = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    _fastForwardView.layer.cornerRadius  = 4;
    _fastForwardView.layer.masksToBounds = YES;
    
    _fastForwardLabel               = [[UILabel alloc] init];
    _fastForwardLabel.textColor     = [UIColor whiteColor];
    _fastForwardLabel.backgroundColor =[UIColor clearColor];
    _fastForwardLabel.textAlignment = NSTextAlignmentCenter;
    _fastForwardLabel.font          = [UIFont systemFontOfSize:15.0];
    [_fastForwardView addSubview:_fastForwardLabel];
    
    _fastForwardImgView             = [[UIImageView alloc] init];
    [_fastForwardView addSubview:_fastForwardImgView];
    
    
    [self addSubview:_fastForwardView];
    
    [self hideFastForwardView];
}

-(void)showFastForwardView:(NSTimeInterval)draggedTime isForward:(BOOL)forawrd{
    
    
    [_fastForwardView setHidden:NO];
    
    
    
    int draggedTimeInt = (int)(floorf(draggedTime));
    
    
    // 拖拽的时长
    NSInteger proMin = draggedTimeInt / 60;//当前分钟
    NSInteger proSec = draggedTimeInt % 60;//当前秒
    
    
    
    NSString *titleStr;
    
    if (forawrd) {
        self.fastForwardImgView.image = [UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_fastforward")];
        
        if (proMin ) {
            titleStr =[NSString stringWithFormat:@"前进%02ld分%02ld秒",(long)proMin,(long)proSec];
            
            NSLog(@"%@",titleStr);
        }else{
            
            titleStr = [NSString stringWithFormat:@"前进%02ld秒",(long)proSec];
            
            NSLog(@"%@",titleStr);
            
        }
        
    } else {
        self.fastForwardImgView.image = [UIImage imageNamed:X1BUNDLE_Image(@"yz_ic_video_fastbackward")];
        
        if (proMin) {
            titleStr =[NSString stringWithFormat:@"后退%02ld分%02ld秒",(long)labs(proMin),(long)labs(proSec)];
            
        }else{
            
            titleStr = [NSString stringWithFormat:@"后退%02ld秒",(long)labs(proSec)];
            
        }
        
        
    }
    self.fastForwardLabel.text = titleStr;
    
    
}

-(void)hideFastForwardView{
    
    [_fastForwardView setHidden:YES];
}




#pragma mark -- Public Method
/**
 *  创建手势
 */
- (void)createGesture {
    if (self.singleTap || self.doubleTap || self.panRecognizer) {
        [self removeGestureRecognizer:self.singleTap];
        [self removeGestureRecognizer:self.doubleTap];
        [self removeGestureRecognizer:self.panRecognizer];
    }
    
    // 单击
    self.singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTapAction:)];
    self.singleTap.delegate                = self;
    self.singleTap.numberOfTouchesRequired = 1; //手指数
    self.singleTap.numberOfTapsRequired    = 1;
    [self addGestureRecognizer:self.singleTap];
    
    // 双击(播放/暂停)
    self.doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapAction:)];
    self.doubleTap.delegate                = self;
    self.doubleTap.numberOfTouchesRequired = 1; //手指数
    self.doubleTap.numberOfTapsRequired    = 2;
    
    [self addGestureRecognizer:self.doubleTap];
    
    // 解决点击当前view时候响应其他控件事件
    //    [self.singleTap setDelaysTouchesBegan:YES];
    //    [self.doubleTap setDelaysTouchesBegan:YES];
    // 双击失败响应单击事件
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
    
    //    // 添加平移手势，用来控制音量、亮度、快进快退
    self.panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    self.panRecognizer.delegate = self;
    [self.panRecognizer setMaximumNumberOfTouches:1];
    //    [self.panRecognizer setDelaysTouchesBegan:YES];
    //    [self.panRecognizer setDelaysTouchesEnded:YES];
    //    [self.panRecognizer setCancelsTouchesInView:NO];
    [self addGestureRecognizer:self.panRecognizer];
    
    
}

-(void)clickDefinitioBtn{
    
    [self.controls hideControls:nil];

    
    [self addSubview:self.definitionView];
    self.definitionView.frame = self.bounds;
    
    [self.definitionView addSubview:self.definitionTableView];

    self.definitionTableView.backgroundColor =[[UIColor blackColor] colorWithAlphaComponent:0.7];
    //初始化在屏幕外
    self.definitionTableView.frame = CGRectMake(self.bounds.size.width, 0, 150, self.bounds.size.height);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.definitionTableView.transform = CGAffineTransformMakeTranslation(-150, 0);
    }];
    
    [self.definitionTableView reloadData];
}











#pragma mark -- Action
//点击了锁屏按钮
-(void)clickLockBtn:(YZMoviePlayerControlButton *)sender{
    
    sender.selected = !sender.isSelected;
    
    if (sender.isSelected) {
        self.controls.isLocked = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerViewOnClickLockScreenBtnNotification object:nil];
        
    }else{
        self.controls.isLocked = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:X1PlayerViewOnClickUnLockScreenBtnNotification object:nil];
        
    }
    
}

/**
 *   轻拍方法
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)singleTapAction:(UIGestureRecognizer *)gesture{
    
    if (self.controls.moviePlayer.playerMediaState == PS_PLAYING || self.controls.moviePlayer.playerMediaState == PS_SEEKTO) {
        self.controls.isShowing ? [self.controls hideControls:nil] : [self.controls showControls:nil autoHide:YES];
    }
}

/**
 *  双击播放/暂停
 *
 *  @param gesture UITapGestureRecognizer
 */
- (void)doubleTapAction:(UIGestureRecognizer *)gesture{
    
    [self.controls playPausePressed:nil];
}

///**
// 滑动手势 亮度 音量  进度
//
// @param gesture 滑动手势
// */
- (void)panDirection:(UIPanGestureRecognizer *)pan {
    // 根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                self.panDirection = PanDirectionHorizontalMoved;
              
                [self panHorizontalBeginMoved];
            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                
                    [self panHorizontalBeingMoved:veloctyPoint.x];
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalBeingMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self panHorizontalEndMoved];
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}


/** 点击了清晰度视图的返回手势 */
-(void)clickDefinitionBackGesture{
    
    [self.definitionView removeFromSuperview];
    
    self.definitionTableView.transform = CGAffineTransformIdentity;
    
}

#pragma mark -- pan手势具体处理
/** pan开始水平移动 */
- (void)panHorizontalBeginMoved {
    // 给panMoveTotalTime初值
    self.panMoveTotalTime = 0;
}

/** pan水平移动ing */
- (void)panHorizontalBeingMoved:(CGFloat)value {
    
    if (!self.isNeedShowFastforward) {
        return;
    }
    
    //防止中途切换前进/后退
    if ((self.isForward && value >=0)|| (!self.isForward && value<= 0)) {
        // 每次滑动需要叠加时间
        self.panMoveTotalTime =self.panMoveTotalTime + value / 100;
    }else{
        
        self.panMoveTotalTime = value/100;
    }
    

//    NSLog(@"value %f",value);
//
//    NSLog(@"panMoveTime %f",self.panMoveTotalTime);
//
    // 需要限定sumTime的范围
    CGFloat totalMovieDuration = self.controls.moviePlayer.duration;
    
    if (self.panMoveTotalTime > totalMovieDuration) { self.panMoveTotalTime = totalMovieDuration;}
    if (self.panMoveTotalTime < -totalMovieDuration) { self.panMoveTotalTime = -totalMovieDuration; }

    if (value > 0) { self.isForward = YES; }
    if (value < 0) { self.isForward = NO; }
    if (value == 0) { return; }
    
//    self.playerStatusModel.dragged = YES;
    
    
    // 展示快进/快退view
    [self showFastForwardView:self.panMoveTotalTime isForward:self.isForward];
    
}

/** pan结束水平移动 */
- (void)panHorizontalEndMoved {
    
    if (!self.isNeedShowFastforward) {
        return;
    }
    
    // 隐藏快进/快退view
    [self hideFastForwardView];
    
    double totalTime = floor(self.controls.moviePlayer.duration);
    double currentTime = floor(self.controls.moviePlayer.currentPlaybackTime +  self.panMoveTotalTime);
    if (currentTime > self.controls.moviePlayer.duration) {
        currentTime = self.controls.moviePlayer.duration;
    }else if (currentTime < 0 ){
        currentTime = 0;
    }
    
    [self.controls stopDurationTimer];
    [self.controls setTimeLabelValues:currentTime totalTime:totalTime];
    [self.controls.moviePlayer setCurrentPlaybackTime:currentTime];

}


/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalBeingMoved:(CGFloat)value {
    if (self.isVolume) {
        [self changeVolume:value];
    } else {
        ([UIScreen mainScreen].brightness -= value / 10000);
    }

}


#pragma mark --UIGestureRecognizerDelegate
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    //
    //    if ([touch.view isDescendantOfView:self.controls.topBar] || [touch.view isDescendantOfView:self.controls.bottomBar] || [touch.view isKindOfClass:[QNButton class]]) {
    //        return NO;
    //    }
    //
    //    return YES;
    //
    
    //如果点击视图为uitableview 则忽略手势
    //  NSLog(@"view class:%@",[touch.view class]);
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]){
        return NO;
    }
    return YES;
}



#pragma mark  -- UITableViewDataSource && UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    
    return self.mediasourceDefinitionArr.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    YZMutipleDefinitionModel *definitionModel = self.mediasourceDefinitionArr[indexPath.row];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    cell.backgroundColor =[UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.font =[UIFont systemFontOfSize:15];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = definitionModel.title;
    if (definitionModel.isSelected) {
        cell.textLabel.textColor = YZColorFromRGB(0xcf5b50);
    }else{
        
        cell.textLabel.textColor = [UIColor whiteColor];

    }

    
    return cell;
    
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *emptyView =[[UIView alloc] init];
    emptyView.backgroundColor =[UIColor clearColor];
    
    return emptyView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    
    CGFloat headerHeight = (tableView.frame.size.height - tableView.rowHeight * [tableView numberOfRowsInSection:0] )  / 2  - tableView.tableHeaderView.frame.size.height;

    
    return headerHeight > 0 ? headerHeight:0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    YZMutipleDefinitionModel *definitionModel = self.mediasourceDefinitionArr[indexPath.row];
    
    if (definitionModel.isSelected) {
        return;
    }

    for (YZMutipleDefinitionModel *model in self.mediasourceDefinitionArr) {
        model.isSelected = NO;
    }
    
    definitionModel.isSelected = YES;
    
    if (definitionModel.url) {
        
        [self.controls.moviePlayer changeContentURL:definitionModel.url];
    }
    
    [self clickDefinitionBackGesture];
    [self.controls setupDefinitionBtn];

}



#pragma mark  -- Setter && Getter

- (void)setIsNeedShowFastforward:(BOOL)isNeedShowFastforward{
    
    _isNeedShowFastforward = isNeedShowFastforward;

    
}

-(void)setControls:(YZMoviePlayerControls *)controls{
    
    _controls = controls;
    
    if (self.controls.moviePlayer.movieFullscreen) {
        [self addSubview:self.lockBtn];
        
    }else{
        
        [self.lockBtn removeFromSuperview];
    }
    
}


-(UIView *)definitionView{
    
    if (!_definitionView) {
        
        _definitionView =[[UIView alloc] init];
        
        // 单击返回
        UITapGestureRecognizer *backGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickDefinitionBackGesture)];
        backGesture.delegate                = self;
        backGesture.numberOfTouchesRequired = 1; //手指数
        backGesture.numberOfTapsRequired    = 1;
//        backGesture.cancelsTouchesInView = NO;
        [_definitionView addGestureRecognizer:backGesture];
    }
    
    return _definitionView;
}

-(UITableView *)definitionTableView{
    
    if (!_definitionTableView) {
        
        _definitionTableView =[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        
        _definitionTableView.delegate = self;
        
        _definitionTableView.dataSource = self;
        
        _definitionTableView.rowHeight = 45;
        
        _definitionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        UILabel *headerLabel =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 70)];
        headerLabel.font =[UIFont systemFontOfSize:15];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.text = @"请选择清晰度";
        headerLabel.textColor = [UIColor whiteColor];
        
        _definitionTableView.tableHeaderView = headerLabel;
        
    }
    
    return _definitionTableView;
    
}




@end
