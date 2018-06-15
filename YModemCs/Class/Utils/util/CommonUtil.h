//
//  CommonUtil.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CommonUtil : NSObject

+(CommonUtil*)sharedManager;

-(NSMutableData *)dataFromHexString:(NSString *)string;

-(UIColor *) stringTOColor:(NSString *)str;


@end
