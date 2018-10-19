//
//  ColorUtil.m
//  NetPhone
//
//  Created by AHQN on 13-12-19.
//  Copyright (c) 2013年 青牛软件. All rights reserved.
//

#import "YZColorUtil.h"

@implementation YZColorUtil

//16进制颜色(html颜色值)字符串转为UIColor
+(UIColor *) hexStringToColor: (NSString *) stringToConvert {
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6、7(#)、8、10 characters
    if ([cString length] < 6) {
        return [UIColor blackColor];
    }
    // strip #if it appears
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) {
        cString = [cString substringFromIndex:2];
    }
    float alpha = 1.0f;
    NSRange range;
    range.length = 2;
    if ([cString length] == 8) {  // 包含透明度
        range.location = 0;
        NSString *aString = [cString substringWithRange:range];
        unsigned int a;
        [[NSScanner scannerWithString:aString] scanHexInt:&a];
        alpha = (float)a / 255.0f;
        cString = [cString substringFromIndex:2];
    } else if([cString length] != 6){
        return [UIColor blackColor];
    }
    // Separate into r, g, b substrings
    
    range.location = 0;
    NSString *rString = [cString substringWithRange:range];
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:alpha];
}

// 生成纯色image
+ (UIImage *)createImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}

@end
