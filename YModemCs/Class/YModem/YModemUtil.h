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


typedef enum : NSUInteger {
    OTAStatusNONE,
    OTAStatusWaiting,
    OTAStatusFirstOrder,
    OTAStatusBinOrder,
    OTAStatusBinOrderDone,
    OTAStatusEnd,
    OTAStatusCAN,
    OTAStatusEOT,
} OTAStatus;


typedef enum : NSUInteger {
    OrderStatusNONE,
    OrderStatusC,
    OrderStatusACK,
    OrderStatusNAK,
    OrderStatusCAN,
    OrderStatusFirst,
} OrderStatus;



//设置代理方法
@protocol YModemUtilDelegate <NSObject>

//写入蓝牙数据
-(void)onWriteBleData:(NSData*) data;

//-(void)onCurrent:(NSInteger)current onTotal:(NSInteger)total;

@end

@interface YModemUtil : NSObject

@property (nonatomic, weak) id<YModemUtilDelegate> delegate;

@property (nonatomic, strong) NSArray  *packetArray;

@property (nonatomic, assign) OTAStatus status;


//文件格式
-(void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status fileName:(NSString *)filename completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;


//NSData格式
- (void)setFirmwareHandlerDFUDataWithOrderStatus:(OrderStatus)status fileData:(NSData *)data completion:(void(^)(NSInteger current,NSInteger total,NSString *msg))complete;



- (NSData *)prepareFirstPacketWithFileName:(NSString *)filename;

-(void)stopOtaUpgrad;

- (instancetype)init:(uint32_t)size;


@end
