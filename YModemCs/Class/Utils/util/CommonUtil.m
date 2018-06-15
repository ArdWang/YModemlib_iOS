//
//  CommonUtil.m
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import "CommonUtil.h"

@implementation CommonUtil

static CommonUtil *sharedSingleton = nil;

/*
 *
 单列模式给外部调用
 */
+(CommonUtil*)sharedManager{
    static dispatch_once_t once;
    dispatch_once(&once,^{
        sharedSingleton = [[self alloc] init];
    });
    
    return sharedSingleton;
}

/*
 * 字符串转为颜色值
 */
-(UIColor *) stringTOColor:(NSString *)str
{
    if (!str || [str isEqualToString:@""]) {
        return nil;
    }
    unsigned red,green,blue;
    NSRange range;
    range.length = 2;
    range.location = 1;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&red];
    range.location = 3;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&green];
    range.location = 5;
    [[NSScanner scannerWithString:[str substringWithRange:range]] scanHexInt:&blue];
    UIColor *color= [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:1];
    return color;
}


/**
 * Method to convert hex to byteArray
 */
-(NSMutableData *)dataFromHexString:(NSString *)string
{
    NSMutableData *data = [NSMutableData new];
    NSCharacterSet *hexSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF "] invertedSet];
    
    // Check whether the string is a valid hex string. Otherwise return empty data
    if ([string rangeOfCharacterFromSet:hexSet].location == NSNotFound) {
        
        string = [string lowercaseString];
        unsigned char whole_byte;
        char byte_chars[3] = {'\0','\0','\0'};
        int i = 0;
        int length = (int)string.length;
        
        while (i < length-1)
        {
            char c = [string characterAtIndex:i++];
            
            if (c < '0' || (c > '9' && c < 'a') || c > 'f')
                continue;
            byte_chars[0] = c;
            byte_chars[1] = [string characterAtIndex:i++];
            whole_byte = strtol(byte_chars, NULL, 16);
            [data appendBytes:&whole_byte length:1];
        }
    }
    return data;
}


@end

