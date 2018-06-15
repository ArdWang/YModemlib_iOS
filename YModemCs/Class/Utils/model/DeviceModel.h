//
//  DeviceModel.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceModel : NSObject
//设备名称
@property(copy,nonatomic) NSString *deviceName;
//设备RSSI的值
@property(copy,nonatomic) NSString *deviceRssi;

@property(copy,nonatomic) NSString *deviceAddre;

@property(assign,nonatomic) BOOL isselect;

@end
