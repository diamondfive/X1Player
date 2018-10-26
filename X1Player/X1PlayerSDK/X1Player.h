//
//  X1Player.h
//
//  Created by 付彦彰 on 2018/7/2.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  Email : fyz333501@163.com
//  GitHub: https://github.com/diamondfive/X1Player
//  如有问题或建议请给我发Email, 或在该项目的GitHub主页lssues我, 谢谢:)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import "X1PlayerCallback.h"

//播放状态改变通知
#define X1PlayerPlaybackStateDidChangeNotification @"X1PlayerPlaybackStateDidChangeNotification"
//媒体播放完成或用户手动退出通知
#define X1PlayerPlaybackDidFinishNotification @"X1PlayerPlaybackDidFinishNotification"
//确定了媒体播放时长后的通知
#define X1PlayerDurationAvailableNotification @"X1PlayerDurationAvailableNotification"
//媒体网络加载状态改变通知
#define X1PlayerLoadStateDidChangeNotification @"X1PlayerLoadStateDidChangeNotification"

typedef NS_ENUM(NSInteger, X1PlayerState) {
    PS_ERROR = -1,
    PS_NONE = 0,
    PS_LOADING = 1, // 加载状态
    PS_PLAYING,     // 播放状态 ，int 毫秒
    PS_BUFFERING,   // Buffer状态，int 前16bit存放类型 0=Audio 1=Video，后16位存放缓冲的进度 0-100
    PS_PAUSED,      // 暂停状态
    PS_STOPED,      // 停止状态
    PS_RECONNECTION,// 重连
    PS_SEEKTO       //seek状态
};

typedef NS_ENUM(NSInteger, X1PlayerError) {
    ERROR_READ_MEDIA_FORMAT=3001,   //读媒体格式错误
    ERROR_READ_DATA=3002,           //读数据错误
    ERROR_CONNECT_TIMEDOUT=3003,    //连接超时
    ERROR_INIT_VIDEO_CODEC=3004,    //初始化视频解码器失败
    ERROR_INIT_AUDIO_CODEC=3005,    //初始化音频解码器失败
    ERROR_READ_TIMEDOUT=3006,       //读数据超时
    ERROR_HOST_UNREACH=3007,        //网络主机不可达
    ERROR_HOST_DOWN=3008,           //网络主机已下线
    ERROR_CONNECT_REFUSED=3009,     //网络连接被拒绝
    ERROR_NETWORK_DOWN=3010,        //网络已宕
    ERROR_NETWORK_UNREACH=3011,     //网络不可达
    ERROR_NETWORK_RESET=3012,       //网络被重置
    ERROR_CONNECT_ABORTED=3013,     //连接被放弃
    ERROR_CONNECT_RESET=3014,       //连接被重置
    ERROR_IO=3015                   //IO错误
};


typedef NS_ENUM(NSInteger, X1PlayerNotifyID) {
    NOTIFY_DATA_TIMEDOUT = 1001, //数据接收超时：加载时3秒没加载到数据，缓冲时3秒没有缓冲到数据
    NOTIFY_TIMESHIFT_NODATA = 1002 //时移拖到指定位置没有数据回调
};


@interface X1Player : NSObject {
    
}

//媒体时长
@property (nonatomic, readonly) int duration;
//可播放时长
@property (nonatomic, readonly) int playableDuration;
//播放器状态
@property (nonatomic, readonly) X1PlayerState playbackState;

/**
 * 创建播放器实例[直播和点播]
 * @param    object
 */
- (X1Player *) initX1PlayerInstance:(id<X1PlayerAgentDelegate>) delegate;
/**
 * 初始化播放器[直播和点播]
 */
- (void) Init;
/**
 * 设置视频显示颜色模式[直播和点播]
 * @param mode=0为彩色模式(正常模式)，mode=1为黑白模式
 * @return 0=表示设置成功，非0表示失败
 * @note 需要在启动播放前调用设置
 */
- (int) SetColorMode:(int) mode;
/**
 * 设置媒体数据源[直播和点播]
 * @param    source  媒体数据源
 */
- (void) setDataSource:(NSString *) source;
/**
 * 设置媒体数据源[直播和点播]
 * @param    source1  媒体数据源1
 * @param    source2  媒体数据源2
 */
- (void) setDataSource:(NSString *) source1 source2:(NSString *) source2;

/**
 * 设置时移播放地址
 * @param
 *  TSDomain:时移域名
 *    LiveCID:直播节目CID
 *    LiveDomain:直播域名
 *    TSStartTime:时移节目开始时间，格式：yyyyMMddhhmmss，例如：20170730162846
 *    TSEndTime:时移节目结束时间，格式：yyyyMMddhhmmss，例如：20170730162846
 */
- (int) setDataSource:(NSString *) tsDomain LiveCID:(NSString *) liveCID LiveDomain:(NSString *) liveDomain TSStartTime:(NSString *) tsStartTime TSEndTime:(NSString *) tsEndTime;

/**
 * 通知时移节目直播结束
 * @param  TSLiveEndTime:直播节目结束时间，格式：yyyyMMddhhmmss，例如：20170730162846
 */
- (int) notifyTSLiveEnd:(NSString *) tsLiveEndTime;

/**
 * 获取时移节目时长，单位：毫秒
 */
- (int) getTSDuration;

/**
 * 获取当前播放的数据源[直播和点播]
 * @return  当前播放的媒体数据源
 */
- (NSString *) getDataSource;
/**
 * 设置用于显示媒体视频的view[直播和点播]
 * @param    view  显示媒体视频的view
 */
- (void) setDisplay:(GLKView *) view;
/**
 * 预处理播放器为播放做准备[直播和点播]
 */
- (void) prepareAsync;
/**
 * 开始播放[直播和点播]
 */
- (void) start;
/**
 * 播放暂停[点播]
 */
- (void) pause;
/**
 * 播放停止[直播和点播],停止后无法断点续播
 */
- (void) stop;
/**
 * 播放由暂停切换到继续播放[点播]
 */
- (void) resume;
/**
 * 重连[直播]
 */
- (void) restart;
/**
 * 获取播放媒体资源的总时长[点播]
 * @return  媒体资源当前播放时长，单位为ms
 */
- (int) getDuration;
/**
 * 设置到指定时间位置播放[点播]
 * @param    time  单位为ms
 */
- (void) seekTo:(int) time;
/**
 * 获得当前播放位置[点播]
 */
- (int) getCurrentPosition;
/**
 * 释放与Player相关的资源[直播和点播]
 */
- (void) releasePlayer;
/**
 * 设置音量[直播和点播]
 * @param    value  音量值范围：0-100
 */
- (void) setVolume:(int) value;
/**
 * 静音设置[直播和点播]
 * @param    value  静音设置，1=静音、0=取消静音
 */
- (void) mute:(int) value;
/**
 * 退出不成功调用killThread强杀线程
 */
- (void) killThread;
/**
 * 设置appkey[直播和点播]
 * @param    value  appkey app名称
 */
- (void) setAppKey:(NSString *) appkey;
/**
 * 横竖屏切换时调用[直播和点播]
 * @param view  视频view
 */
- (void) UIViewDidChange:(GLKView *) view;
/**
 * 出错时进行重连[直播和点播]
 */
- (void) RetryPlay;
/**
 * 判断是直播还是点播[直播和点播]
 */
- (Boolean) isLive;
/**
 * 设置呼叫主叫被叫号码
 */
- (void) setCallInfo:(NSString *) caller called:(NSString *) called;
/**
 * 设置呼叫session ID
 */
- (void) setSessionID:(NSString *) sessionID;
/**
 * 设置呼叫挂断原因
 */
- (void) setHangUpReason:(int) reason;
/**
 * 发送呼叫信息xml
 */
- (void) sendPlayCallReportInfo:(NSString *) subType;
/**
 * 设置业务标识 如果用户有登录，则有这个用户的标识
 */
- (void) setBusinessID:(NSString *) businessID;
/**
 * 显示用户名称 如果用户有登录，则有这个参数用户名
 */
- (void) setUserName:(NSString *) userName;

/**
 * 设置直播是否追延时
 * @param value  true 追延时 false 取消追延时
 */
- (void) setLiveNoDelay:(BOOL) value;

- (void) setAllDelegate:(id) delegate;
- (void) onActionInvoke:(int) flag data:(int) data;
- (void) onPlayableDurationInvoke:(int) time;
- (void) onExtraDataInvoke:(char*) data datalen:(int) datalen;

- (void) getX1PlayerInstance:(X1Player *) player;@end


