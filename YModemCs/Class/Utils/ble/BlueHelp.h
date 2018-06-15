//
//  BlueHelp.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlueHelp.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "DeviceModel.h"
#import "Constants.h"
#import "CommonUtil.h"

@interface BlueHelp : NSObject

+ (id)sharedManager;

//蓝牙的设备搜索显示在列表中
@property (nonatomic, strong) NSMutableArray <CBPeripheral*>*periperals;

//连接peripheral
@property(nonatomic,strong) CBPeripheral *peripheral;

//中心管理者
@property (nonatomic, strong) CBCentralManager *centerManager;

//设备列表
@property (nonatomic,strong) NSMutableArray *deviceList;

@property (nonatomic,strong) DeviceModel *deviceModel;

//发送OTA数据
@property (nonatomic,strong) CBCharacteristic *sendotacharateristic;

-(void)contentBlue:(int) row;

-(void)startScan;

-(void)stopScan;

-(NSMutableArray *)getDeviceList;

-(NSMutableArray *)getPeriperalList;

-(void)writeBlueOTA:(NSString *)value;

-(void)wirteBleOTAData:(NSData *)value;

//断开蓝牙
-(void)disContentBle;

@end
