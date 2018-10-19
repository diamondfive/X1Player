//
//  QNColorUtil.h
//  NetPhone
//
//  Created by AHQN on 13-12-19.
//  Copyright (c) 2013年 青牛软件. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define COLOR(R, G, B, A) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]

@interface YZColorUtil : NSObject

+(UIColor *) hexStringToColor:(NSString *) stringToConvert;

+ (UIImage *)createImageWithColor:(UIColor *)color;

@end
