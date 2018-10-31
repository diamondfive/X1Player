//
//  YZMutipleDefinitionModel.h
//  X1Player
//
//  Created by 付彦彰 on 2018/10/25.
//  Copyright © 2018年 channelsoft. All rights reserved.
//  多清晰度视频模型

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YZMutipleDefinitionModel : NSObject

//清晰度标题 eg. 标清 高清 超清
@property (nonatomic, strong) NSString *title;
//播放地址
@property (nonatomic, strong) NSString *url;

@property (nonatomic, assign) BOOL isSelected;

@end

NS_ASSUME_NONNULL_END
