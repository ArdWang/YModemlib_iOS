//
//  YModemUtil.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YModem.h"
#import "Constants.h"

//设置代理方法
@protocol YModemUtilDelegate <NSObject>

//写入蓝牙数据
-(void)onWriteBleData:(NSData*) data;

-(void)onCurrent:(NSInteger)current onTotal:(NSInteger)total;

@end

@interface YModemUtil : NSObject

@property (nonatomic, weak) id<YModemUtilDelegate> delegate;

@property (nonatomic, strong) NSArray  *packetArray;

- (void)setOTADataWithOrderStatus:(NSString *)status fileName:(NSString *)filename;


@end
