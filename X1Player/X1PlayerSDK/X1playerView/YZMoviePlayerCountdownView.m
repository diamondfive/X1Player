//
//  YZMoviePlayerCountdownView.m
//  X1PlayerSDK
//
//  Created by 付彦彰 on 2018/6/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//

#import "YZMoviePlayerCountdownView.h"
#import "YZColorUtil.h"



//倒计时计时器走完通知
NSString * const QNCountdownTimeoutNotification = @"QNCountdownTimeoutNotification";

@interface YZMoviePlayerCountdownView()

@property(nonatomic, assign)NSTimeInterval startTimeInterval;//开始时间戳

@property(nonatomic, assign)NSTimeInterval currentTimeInterval;//当前时间戳

@property(nonatomic, strong)UIView *noStartView;

@property(nonatomic, strong)UILabel *noStartTitleLable;//距离直播开始还有

@property(nonatomic, strong)UILabel *noStartCountDownLabel;//倒计时

@property(nonatomic, strong)UILabel *leftTopStartTimeLabel;//左上角即将开始悬浮窗



@end

@implementation YZMoviePlayerCountdownView


-(instancetype)initWithStartTimeInterval:(NSTimeInterval)startTimeInterval{
    
    if (self =[super init]) {
        
        self.startTimeInterval = startTimeInterval;
        [self initConfig];
    }
    return self;
}


-(instancetype)initWithStartTimeInterval:(NSTimeInterval)startTimeInterval  currentTimeInterval:(NSTimeInterval)currentTimeInterval{
    
    if (self =[super init]) {
       
        self.startTimeInterval = startTimeInterval;
        self.currentTimeInterval = currentTimeInterval;
        [self initConfig];
    }
    return self;
    
}

-(void)initConfig{
    

    //开播前视图
    self.noStartView = [[UIView alloc] init];
    self.noStartView.backgroundColor =[[UIColor darkGrayColor] colorWithAlphaComponent:0.9];
    [self addSubview:self.noStartView];
   
    
    NSDate *startDate =[[NSDate alloc]initWithTimeIntervalSince1970:self.startTimeInterval];
    //用于格式化NSDate对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设置格式：zzz表示时区
    [dateFormatter setDateFormat:@"MM.dd HH:mm"]; //NSDate转NSString
    NSString *currentDateString = [dateFormatter stringFromDate:startDate];
    
    //左上角悬浮窗
    self.leftTopStartTimeLabel =[[UILabel alloc] init];
    self.leftTopStartTimeLabel.layer.cornerRadius = 3;
    self.leftTopStartTimeLabel.layer.masksToBounds = YES;
    self.leftTopStartTimeLabel.backgroundColor =[YZColorUtil hexStringToColor:@"#3AA151"];
    self.leftTopStartTimeLabel.text =[NSString stringWithFormat:@"　即将开始 %@　",currentDateString];
    self.leftTopStartTimeLabel.textColor =[UIColor whiteColor];
    self.leftTopStartTimeLabel.font =[UIFont systemFontOfSize:12];
    [self.leftTopStartTimeLabel sizeToFit];
    [self.noStartView addSubview:self.leftTopStartTimeLabel];

    
    
    
    
    //开播前标题(距离直播开始XX)
    self.noStartTitleLable =[[UILabel alloc] init];
    self.noStartTitleLable.font =[UIFont systemFontOfSize:22];
    self.noStartTitleLable.textColor = [UIColor whiteColor];
    self.noStartTitleLable.text =@"距离直播开始还有";
    [self.noStartTitleLable sizeToFit];
    [self.noStartView addSubview:self.noStartTitleLable];

    
    //倒计时label
    self.noStartCountDownLabel =[[UILabel alloc] init];
    self.noStartCountDownLabel.textColor = [UIColor whiteColor];
    self.noStartCountDownLabel.font = [UIFont boldSystemFontOfSize:28];
    
    [self.noStartView addSubview:self.noStartCountDownLabel];

    
    //计时器
    self.countDownTimer =[NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateCountDownLabel) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.countDownTimer forMode:NSRunLoopCommonModes];
    [self.countDownTimer fire];
    
 
}

-(void)updateCountDownLabel{
    
//    NSLog(@"QN倒计时器还活着");
    NSDate *nowTime =[NSDate date];
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:self.startTimeInterval];
    
    NSString *timeStr = [self dateStringBetween:nowTime to:startTime];
    
    self.noStartCountDownLabel.text = timeStr;
    [self.noStartCountDownLabel sizeToFit];
    [self.noStartCountDownLabel setNeedsLayout];
    [self.noStartCountDownLabel layoutIfNeeded];

    
    //检测是否已经到了开播时间
    
    NSTimeInterval gap = [startTime timeIntervalSinceDate:nowTime];
    if (gap <= 0 ) { //时间到了
        
        [[NSNotificationCenter defaultCenter] postNotificationName:QNCountdownTimeoutNotification object:nil];
        
        [self.countDownTimer invalidate];
        self.countDownTimer = nil;
        [self removeFromSuperview];
        
    }
    
}

//to 的时间要大于 from  显示时分秒
-(NSString *)dateStringBetween:(NSDate *)from to:(NSDate *)to{
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSUInteger unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *components = [gregorian components:unitFlags
                                                fromDate:from
                                                  toDate:to options:0];
    NSString *timeStr = [NSString stringWithFormat:@"%02ld  :  %02ld  :  %02ld", (long)components.hour, (long)components.minute, (long)components.second];
    
    return timeStr;
    
}

-(void)dealloc{
    
    NSLog(@"QN倒计时视图挂了");
}


-(void)layoutSubviews{
    
    [super layoutSubviews];
    
    self.noStartView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    self.leftTopStartTimeLabel.frame = CGRectMake(20, 10, self.leftTopStartTimeLabel.bounds.size.width, 20);
    
    self.noStartTitleLable.frame = CGRectMake(self.bounds.size.width/2 - self.noStartTitleLable.bounds.size.width/2, (self.bounds.size.height/2 - self.noStartTitleLable.bounds.size.height/2) -10, self.noStartTitleLable.bounds.size.width, self.noStartTitleLable.bounds.size.height);
    
    self.noStartCountDownLabel.frame = CGRectMake(self.bounds.size.width/2 - self.noStartCountDownLabel.bounds.size.width/2, self.bounds.size.height/2 + self.noStartCountDownLabel.bounds.size.height/2 , self.noStartCountDownLabel.frame.size.width, self.noStartCountDownLabel.frame.size.height);
    
}


@end
