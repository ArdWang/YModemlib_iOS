//
//  OTAManager.h
//  YModemCs
//
//  Created by rnd on 2018/6/14.
//  Copyright © 2018年 GoDream. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    OTAStatusNONE,
    OTAStatusWaiting,
    OTAStatusFirstOrder,
    OTAStatusBinOrder,
    OTAStatusBinOrderDone,
    OTAStatusEnd,
    OTAStatusCAN,
} OTAStatus;

typedef enum : NSUInteger {
    OrderStatusNONE,
    OrderStatusC,
    OrderStatusACK,
    OrderStatusNAK,
    OrderStatusCAN,
} OrderStatus;

@interface OTAManager : NSObject

@property (nonatomic, assign) OTAStatus status;

/**
 * @brief 下位机进入OTA模式
 */
- (void)setFirmwareEnterOTAMode;

/** 下位机进入Ymodem数据下载模式
 *
 */
- (void)setFirmwareEnterYmodemDataDownloadMode;

/**
 * @brief 下位机退出OTA模式
 */
- (void)setFirmwareExitOTAMode;

/**
 * @brief 处理OTA数据
 * @param status OTA指令
 * @param complete OTA状态回调
 */
- (void)setFirmwareHandleOTADataWithOrderStatus:(OrderStatus)status completion:(void(^)(NSString *message))complete;

- (NSData *)prepareFirstPacketWithFileName:(NSString *)filename;

- (NSArray *)preparePacketWithFileName:(NSString *)filename;

- (NSData *)prepareEndPacket;

@end


