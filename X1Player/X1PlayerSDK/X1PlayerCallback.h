//
//  X1PlayerCallback.h
//  mediaplayer
//
//  Created by Gexy on 15/11/11.
//  Copyright (c) 2015年 Butel. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef mediaplayer_X1PlayerCallback_h
#define mediaplayer_X1PlayerCallback_h

@interface X1PlayerCallback : NSObject

@end

typedef struct X1ADData {
    int OriginTop;
    int OriginLeft;
    int OriginWidth;
    int OriginHeight;
    
    int Top;
    int Left;
    int Width;
    int Height;
    
    short Layer;
    short adCount;
    int* IDs;
}X1ADData;

typedef struct X1ADDatas {
    short regionCount;
    X1ADData* ads;
}X1ADDatas;

// X1PlayerAgentDelegate回调类
@protocol X1PlayerAgentDelegate <NSObject>

/** 播放加载回调
 @param loadingflag 为1时表示媒体格式信息加载完成
 @return void
 */
- (void) onLoading:(int) loadingflag;

/** 播放缓冲回调
 @param percent 已缓冲的百分比数(0-100)
 @return void
 */
- (void) onBufferingUpdate:(int) percent;

/** 播放开始回调
 在媒体预处理完成后调用
 @param 无
 @return void
 */
- (void) onPrepared;

/** 当前播放时间实时显示回调
 @param currentPos 当前播放的时间,单位:ms
 @return void
 */
- (void) onPlayingUpdate:(int) currentPos;

/** 播放完成回调
 @param 无
 @return void
 */
- (void) onCompletion;

/** 快进快退回调
 @param 无
 @return void
 */
- (void) onSeekComplete;

/** 错误处理回调
 @param what 错误码
 extra 额外的错误信息
 @return void
 */
- (BOOL) onError:(int) what extra:(int) extra;

/** 停止结束回调
 @param 无
 @return void
 */
- (void) onStopComplete;

/** 交互数据回调
 @param data 交互数据。
 state 交互数据开始和结束状态，1=开始，0=结束。
 type 数据类型
 data_length 数据长度
 time_stamp 数据的时间戳
 @return void
 */
- (void) onExtraData:(char*) data state:(int) state type:(short) type data_length:(short) data_length time_stamp:(int) time_stamp;

/** 交互数据回调2
 @param state 交互数据开始和结束状态，1=开始，0=结束。
 type 数据类型
 data_length 数据长度
 time_stamp 数据的时间戳
 ADDatas 广告数据
 @return void
 */
- (void) onExtraData2:(int) state type:(short) type data_length:(short) data_length time_stamp:(int) time_stamp addatas:(X1ADDatas *) addatas;

/** 可播放时长回调
 @param playableDuration 可播放时长，单位ms
 @return void
 */
- (void) onPlayableDuration:(int) playableDuration;

/** 播放器通知回调
 @param NotifyID notify消息ID
 @return void
 */
- (void) onNotify:(int) NotifyID;
@end

#endif
